# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# File system - eza-based ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias ll='ls -lah'
  alias lr='ls -lahsnew'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  # Fallback to standard ls if eza is not installed
  alias ls='ls -lh --color=auto'
  alias lsa='ls -lah'
fi

alias gg='lazygit'
alias gita='git add'
alias gitc='git commit -m'
alias gitac='git add . && git commit -m'
alias gitl='git log'
alias gitd='git diff'
alias gits='git status'
alias g='git'

alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcub='docker compose up --build'
alias dcudb='docker compose up -d --build'
alias dcbnc='docker compose build --no-cache'
alias dcd='docker compose down'
alias dcpa='docker compose ps -a'
alias dcp='docker compose ps'
alias dcl='docker compose logs'
alias dcs='docker compose stats'

alias dpa='docker ps -a'
alias dp='docker ps'
alias ds='docker stats'

alias q='exit'
alias c='clear'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# editor
export EDITOR='nvim'
alias n='nvim'

# show file system structure trees
alias dtree='tree -C -d --dirsfirst'
alias ftree='tree -C -L 5 --dirsfirst'

# claude code
alias cc='claude'
alias ccw='claude --worktree'
alias ccc='claude --dangerously-skip-permissions'
alias cccw='claude --dangerously-skip-permissions --worktree'
# model variants: o=opus, s=sonnet, 5=4.5, 6=4.6
alias cco5='claude --model claude-opus-4-5'
alias cco6='claude --model claude-opus-4-6'
alias ccs5='claude --model claude-sonnet-4-5'
alias ccs6='claude --model claude-sonnet-4-6'
# worktree + model
alias ccwo5='claude --worktree --model claude-opus-4-5'
alias ccwo6='claude --worktree --model claude-opus-4-6'
alias ccws5='claude --worktree --model claude-sonnet-4-5'
alias ccws6='claude --worktree --model claude-sonnet-4-6'
# dangerously-skip-permissions + model
alias ccco5='claude --dangerously-skip-permissions --model claude-opus-4-5'
alias ccco6='claude --dangerously-skip-permissions --model claude-opus-4-6'
alias cccs5='claude --dangerously-skip-permissions --model claude-sonnet-4-5'
alias cccs6='claude --dangerously-skip-permissions --model claude-sonnet-4-6'
# dangerously-skip-permissions + worktree + model
alias cccwo5='claude --dangerously-skip-permissions --worktree --model claude-opus-4-5'
alias cccwo6='claude --dangerously-skip-permissions --worktree --model claude-opus-4-6'
alias cccws5='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-5'
alias cccws6='claude --dangerously-skip-permissions --worktree --model claude-sonnet-4-6'

alias timer='echo "Timer started. Stop with Ctrl+D." && date && time cat && date'
alias myip='curl -s ifconfig.me'

alias setgitperms='find /srv -maxdepth 2 -name ".git" -type d | xargs -I{} git -C {}/../ config core.sharedRepository group'

# notes
note() { echo "$(date +%F) $*" >>~/notes.md; }
todo() { echo "$(date +%F) [ ] $*" >>~/notes.md; }
notes() { cat ~/notes.md; }

# util fns
clone() { # clone username reponame
  git clone "git@github.com:$1/$2.git"
}
tarscp() { #  tarscp sourcedir destdir port?
  local src="${1%/}"
  local dest="$2"
  local port="${3:-2121}"
  local host="${dest%%:*}"
  local path="${dest##*:}"

  tar czf - "$src" | ssh -p "$port" "$host" "cd '$path' && tar xzf -"
}
serve() { # serve port? dir?
  python3 -m http.server "${1:-5173}" -d "${2:-.}"
}
#mkdir -p && cd
mkcd() { mkdir -p "$1" && cd "$1"; }
# tmux shortcuts
tmux() {
  case "$1" in
  new) command tmux new -s "$2" ;;
  a) command tmux attach -t "$2" ;;
  kill) command tmux kill-session -t "$2" ;;
  *) command tmux "$@" ;;
  esac
}
# extract
ex() {
  for f in "$@"; do
    case "$f" in
    *.tar.gz | *.tgz) tar xzf "$f" ;;
    *.tar.bz2) tar xjf "$f" ;;
    *.tar.xz) tar xJf "$f" ;;
    *.tar) tar xf "$f" ;;
    *.zip) unzip "$f" ;;
    *.gz) gunzip "$f" ;;
    *.7z) 7z x "$f" ;;
    *.rar) unrar x "$f" ;;
    *) echo "ex: unknown format '$f'" ;;
    esac
  done
}

# git prompt fallback (used if starship is not installed)
parse_git_branch() {
  git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
parse_git_dirty() {
  [[ -n "$(git status --porcelain 2>/dev/null)" ]] && echo "*"
}
export PS1='\u@\h \[\033[1;34m\]\w\[\033[0m\] \[\033[1;33m\]$(parse_git_branch)$(parse_git_dirty)\[\033[0m\] \$ '

# starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
  export STARSHIP_CONFIG=~/.config/starship.toml
fi

export PATH="$HOME/.local/bin:$PATH"

# PulseAudio over SSH (works with client-side: RemoteForward 4713 localhost:4713)
if [ -n "$SSH_CONNECTION" ]; then
  export PULSE_SERVER=tcp:localhost:4713
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# richer terminal colors
export COLORTERM=truecolor

# opencode
export PATH=/home/sborit/.opencode/bin:$PATH
