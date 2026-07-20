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

# ── yazi — file manager (cd into wherever you exit from) ──
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

# ── History ──────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── PATH ─────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Default editor ───────────────────────────────────────
# Unset $EDITOR made every tool that falls back to `${EDITOR:-vi}`
# (yazi's folder opener, git commit, crontab -e, visudo, …) try a
# literal `vi`, which isn't installed here (only `vim`) — exit 127.
export EDITOR="vim"
export VISUAL="$EDITOR"

# ── WireGuard VPN (dimarchctl vpn — config in dimarch.conf [vpn]) ────────
alias vpn='dimarchctl vpn up'
alias vpnoff='dimarchctl vpn down'
alias vpnst='dimarchctl vpn status'
alias wg-ui='dimarchctl vpn ui'

# ── Local machine overrides (not tracked — personal hosts/paths/secrets) ──
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
