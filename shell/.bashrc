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

alias q='exit'
alias c='clear'

# editor
export EDITOR='nvim'
alias n='nvim'

# show file system structure trees
alias dtree='tree -C -d --dirsfirst'
alias ftree='tree -C -L 5 --dirsfirst'

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

# claude code
alias cc='claude'
alias ccc='claude --dangerously-skip-permissions'

clone() {
  git clone "git@github.com:$1/$2.git"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
