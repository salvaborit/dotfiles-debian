# ProtonVPN CLI on headless Debian — notes

A fresh `apt install proton-vpn-cli` on a TTY-only Debian box (no graphical
session) sign-ins fine but `protonvpn connect` fails with:

```
An unexpected error occurred. Please try again.
```

This has hit at least three machines. Root cause is three independent Debian
packaging / system gaps stacked on top of each other. `scripts/packages/protonvpn.sh`
handles all three for new installs; this doc explains what they are so a future
me can diagnose if anything regresses.

## Symptom

- `protonvpn signin <user>` — succeeds (the file keyring fallback works).
- `protonvpn connect --country US` — prints the generic "unexpected error"
  message and exits non-zero. The CLI's catch-all swallows the real traceback
  (`proton/vpn/cli/__init__.py` around line 191), so the underlying problem
  isn't visible without digging.

## Three root causes, in the order they bite

### 1. `proton-vpn-daemon` requires kernel headers but doesn't depend on them

`me.proton.vpn.split_tunneling.service` is the daemon the CLI talks to over
D-Bus. On startup it eagerly initializes the app-based split-tunneling socket
monitor, which uses `bcc`/BPF and compiles a BPF program at runtime. That
compile needs:

- `modprobe` on PATH (provided by `kmod`, normally fine)
- `/lib/modules/$(uname -r)/build` — i.e. kernel headers

Without `linux-headers-amd64` the daemon crashes immediately and the CLI gets
`Backend: None` because nothing's listening on D-Bus.

Diagnosis:

```bash
systemctl status me.proton.vpn.split_tunneling.service   # will be failed
sudo /usr/bin/python3 -m proton.vpn.daemon                # shows the BPF error
```

Fix: install kernel headers, restart the daemon.

```bash
sudo apt install -y linux-headers-amd64
sudo systemctl restart me.proton.vpn.split_tunneling.service
```

`linux-headers-amd64` is already in `scripts/packages/core.sh` so a fresh `./install`
covers this.

### 2. `proton-vpn-cli` 1.0.1 doesn't pull the NM backend modules

Older `proton-vpn-cli` versions had `python3-proton-vpn-network-manager` as a
hard dep. The current Debian package dropped it. Without those modules the
connector loads but has no protocol backend, so it never reaches NetworkManager.
Symptom in the log: `Protocol: wireguard / Backend: None` followed by silence.

The five missing packages:

- `python3-proton-vpn-network-manager`
- `python3-proton-vpn-network-manager-wireguard`
- `python3-proton-vpn-network-manager-openvpn`
- `python3-proton-vpn-killswitch-network-manager`
- `python3-proton-vpn-killswitch-network-manager-wireguard`

The CLI registers them via `proton.vpn.core.api.create_registry` which does
`registry.register_from_module('proton.vpn.backend.networkmanager.protocol.wireguard')`
etc. (the proton-loader entry_points story is irrelevant — that import path is
what matters).

Diagnosis:

```bash
python3 -c "from proton.vpn.core.registry import Registry; \
  r = Registry(); \
  r.register_from_module('proton.vpn.backend.networkmanager.protocol.wireguard'); \
  print(r._registry)"
# should print {'wireguard': <class '...Wireguard'>}
# if the module isn't installed you get ModuleNotFoundError
```

Fix: install the five packages. Already handled by `protonvpn.sh`.

### 3. NetworkManager polkit rule requires an active seat — TTY sessions have none

This is the real one. Even with daemon up and backend loaded, the WireGuard
kill switch tries to install a system NM connection and gets:

```
RuntimeError: Error adding KS connection: nm-settings-error-quark: Insufficient privileges (1)
```

Debian's `/usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules`:

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.local && subject.active &&
        (subject.isInGroup ("sudo") || subject.isInGroup ("netdev"))) {
        return polkit.Result.YES;
    }
});
```

`subject.active` is true only for a session on an active seat — i.e. a logged-in
graphical session on `seat0`. On a headless or TTY-only machine `loginctl`
shows `SEAT -` and all sessions are inactive from polkit's perspective. Group
membership doesn't matter; the rule is gated on the active check.

Diagnosis:

```bash
loginctl                          # SEAT column will be "-"
echo $XDG_SESSION_TYPE            # "tty" (not "x11" / "wayland")
```

Fix: drop a polkit rule that grants the action to `netdev` members without
requiring `subject.active`. `protonvpn.sh` installs this at
`/etc/polkit-1/rules.d/49-proton-vpn-netdev.rules`. The user must also be in
the `netdev` group (the script adds them).

This is the standard headless-NM workaround and applies to anything that needs
to mutate system NM connections from a TTY/SSH session, not just ProtonVPN.

## Confirmation that everything's wired up

After a fresh install:

```bash
systemctl is-active me.proton.vpn.split_tunneling.service   # active
python3 -c "import proton.vpn.backend.networkmanager.protocol.wireguard"  # no error
ls /etc/polkit-1/rules.d/49-proton-vpn-netdev.rules         # exists
groups | grep -q netdev && echo OK                          # OK
protonvpn signin <username>
protonvpn connect --country US                              # Connected to US-XX#NNN
```

## Logs worth checking when something breaks differently

- `~/.cache/Proton/VPN/logs/vpn-cli.log` — connector state changes; the CLI
  itself doesn't append the final traceback here, but earlier failures
  (keyring, server-list fetch) show up
- `~/.cache/Proton/VPN/logs/vpn-daemon.log` — split-tunneling daemon
- `sudo journalctl -u me.proton.vpn.split_tunneling.service` — daemon stderr
  including BPF compile errors
- `journalctl --user -n 100` — gnome-keyring / gcr-prompter failures and
  D-Bus activation errors
- `journalctl -n 100 | grep NetworkManager` — NM-side errors during connect

To surface the real traceback the CLI is hiding, replicate the call without
going through `protonvpn`:

```bash
python3 -c "
from proton.vpn.cli import main
main(cli_args=['connect', '--country', 'US'])
"
```

The catch-all in `main()` still re-raises after the print, but running it
this way the traceback lands on stderr instead of being eaten by the installed
script wrapper.

## Aside — the noisy keyring tracebacks

The vpn-cli.log is full of `secretstorage.exceptions.PromptDismissedException`
and `Failed to create the collection: Prompt dismissed.` warnings. These come
from `gnome-keyring-daemon` trying to spawn `gcr-prompter` (which needs a
display) to create the default keyring collection. On a headless box this
always fails, but proton-keyring-linux falls through to its JSON file backend
(`~/.cache/Proton/VPN/keyring/`). The noise is harmless and not the cause of
connect failures — leave it alone.
