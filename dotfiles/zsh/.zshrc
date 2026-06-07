# ── Prompt ───────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Git ──────────────────────────────────────────────────
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline -10"

# ── Navigation ───────────────────────────────────────────
alias ..="cd .."
alias ...="cd ../.."

# ── Terminal tools ────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat'
alias lg='lazygit'
alias reload='source ~/.zshrc'

# ── zoxide — smart cd ────────────────────────────────────
eval "$(zoxide init zsh)"
alias cd='z'

# ── History ──────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── PATH ─────────────────────────────────────────────────
export PATH="/home/dmitry/.local/bin:$PATH"
