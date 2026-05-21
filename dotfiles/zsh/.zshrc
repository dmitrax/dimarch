# Starship prompt
eval "$(starship init zsh)"

# Git aliases
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline -10"

# Convenience
alias ll="ls -la"
alias ..="cd .."

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS    # skip duplicate commands
setopt HIST_IGNORE_SPACE   # skip commands starting with space
setopt SHARE_HISTORY       # share history between terminal sessions
