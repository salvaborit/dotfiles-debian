# dotfiles-debian

Dotfiles for headless Debian-based servers (Debian, Kali). GNU Stow + modular install script.

## Install

```bash
git clone git@github.com:YOUR_USER/dotfiles-debian.git
cd dotfiles-debian
./install                    # no SSH/UFW changes
./install --ssh-port 2121   # configure sshd + UFW on custom port
```

## What's Included

**Stow packages** (symlinked to `$HOME`):

| Package | Contents |
|---|---|
| `shell` | `.bashrc`, `.vimrc`, starship config |
| `tmux` | tmux config + git-status bar script |
| `neovim` | Full LazyVim IDE setup |
| `scripts-local` | tmux-session, tmux-project, tmux-save/restore, terminal-tmux-bash |
| `local` | Wordlist for random session names |
| `claude-home` | Claude Code statusline + sound hooks |

**Packages installed:**

- **Core (apt):** git, vim, tmux, curl, wget, htop, btop, stow, ufw, lazygit, ripgrep, fd-find, jq, openssh-server, net-tools, build-essential, fdisk, dmidecode, lshw, pulseaudio-utils
- **Terminal:** neovim >= 0.11.2 (GitHub releases), starship (curl), eza (gierens repo), Node.js 24 (nvm)
- **Docker:** Docker CE from upstream apt repo

## Audio

Sound hooks route through PulseAudio over SSH. Add to your client SSH config:

```
RemoteForward 4713 localhost:4713
```
