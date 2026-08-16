# ── History ──────────────────────────────────────────────
# Написано до всего остального намеренно: если ниже что-то упадёт, история
# всё равно уже настроена.
#
# INC_APPEND_HISTORY — не косметика. zsh пишет историю, когда шелл ВЫХОДИТ,
# а панели herdr убиваются вместе с сервером, а не выходят, поэтому команды
# сессии до файла не доезжают: после рестарта ↑ показывает состояние с
# момента, когда какой-то шелл последний раз завершился чисто.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt INC_APPEND_HISTORY   # писать сразу, а не на выходе — переживает kill -9
setopt EXTENDED_HISTORY     # таймстемпы (нужны, чтобы осмысленно слить панели)
setopt HIST_IGNORE_ALL_DUPS # повтор команды оставляет только новую запись
setopt HIST_IGNORE_SPACE    # пробел в начале = не записывать (токены, секреты)
setopt HIST_REDUCE_BLANKS   # нормализовать пробелы перед записью
setopt HIST_VERIFY          # !! разворачивается в строку для проверки, не сразу

# SHARE_HISTORY намеренно НЕ включаем: он ещё и ИМПОРТИРУЕТ команды других
# шеллов посреди сессии, поэтому в многопанельном herdr ↑ подмешивает то, что
# только что запустили в соседней панели. Каждая новая панель и так читает файл
# целиком при старте, так что «вчерашние команды на месте» выполняется и без него.

# ── Completions — до fzf's completion.zsh ────────────────
# Без compinit дополнение подкоманд и флагов (git, systemctl, docker, paru)
# не работает вообще — Tab дополняет только пути.
autoload -Uz compinit && compinit

# ── fzf ──────────────────────────────────────────────────
# Ctrl+R — история, Ctrl+T — файлы, Alt+C — переход в каталог.
source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ── Navigation — zoxide на cd + стек каталогов ───────────
# `--cmd cd` подменяет cd обёрткой zoxide, поэтому `cd dimarch` из любого места
# прыгает в ~/Projects/dimarch по frecency. Обычный cd при этом не меняется:
# обёртка отдаёт встроенному cd реальный путь, `cd` без аргумента, `cd -`,
# `cd -2` и `cd -- <path>`, а в базу лезет только когда аргумент — НЕ
# существующий каталог. Прежний `alias cd='z'` гнал через z и это тоже.
eval "$(zoxide init zsh --cmd cd)"

# Старые имена оставлены алиасами — `--cmd cd` переименовывает z/zi в cd/cdi,
# и мышечная память на `z` ломаться не должна.
alias z='cd'
alias zi='cdi'   # интерактивный fzf-выбор по базе

# Стек каталогов: каждый cd пушится, поэтому `cd -2` отступает на два шага,
# а `d` печатает стек с индексами.
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
alias d='dirs -v'

alias ..="cd .."
alias ...="cd ../.."

# ── Terminal tools ────────────────────────────────────────
# `--icons=auto`, а НЕ голый `--icons`: значение у флага необязательное, поэтому
# отдельным словом он съедает следующий аргумент — `ls somedir` падает с
# `invalid value 'somedir' for '--icons [<WHEN>]'`, а в конвейере ошибка уходит
# в stderr и остаётся пустой stdout, который читается как «каталог пуст».
#
# Функции, а не алиасы, ради `"${@:-.}"`: eza 0.23.5, вызванная без аргумента-
# пути, не печатает НИЧЕГО, когда stdout не терминал (код возврата 0). С TTY
# работает, поэтому интерактивно баг незаметен, но `ls | grep x`, `$(ls)` и
# любой агент, читающий вывод, молча получают пустоту. `eza .` работает всегда.
ls() { eza --icons=auto "${@:-.}" }
ll() { eza -la --icons=auto --git "${@:-.}" }
la() { eza -la --icons=auto "${@:-.}" }
lt() { eza --tree --icons=auto --level=2 "${@:-.}" }
alias cat='bat'
alias lg='lazygit'
alias reload='source ~/.zshrc'

# ── Git ──────────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate'

# ── herdr — terminal workspace manager for AI coding agents ──
alias h='herdr'                             # запустить или подключиться
alias hs='herdr status'                     # состояние клиента и сервера
alias hstop='herdr server stop'             # остановить фоновый сервер
alias hreload='herdr server reload-config'  # применить config.toml без рестарта
alias hcheck='herdr config check'           # проверить config.toml

# ── yazi — file manager (cd into wherever you exit from) ──
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

# ── System ───────────────────────────────────────────────
alias ports='lsof -nP -iTCP -sTCP:LISTEN'   # что слушает и на каком порту
alias paths='print -l $path'                # PATH по одной записи на строку
alias pacup='paru -Syu'                     # спросит пароль sudo интерактивно
alias dim='cd ~/Projects/dimarch'           # главный репозиторий

# ── WireGuard VPN (dimarchctl vpn — config in dimarch.conf [vpn]) ────────
alias vpn='dimarchctl vpn up'
alias vpnoff='dimarchctl vpn down'
alias vpnst='dimarchctl vpn status'
alias wg-ui='dimarchctl vpn ui'

# ── PATH ─────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Default editor ───────────────────────────────────────
# Unset $EDITOR made every tool that falls back to `${EDITOR:-vi}`
# (yazi's folder opener, git commit, crontab -e, visudo, …) try a
# literal `vi`, which isn't installed here (only `vim`) — exit 127.
export EDITOR="vim"
export VISUAL="$EDITOR"

# ── Prompt — грузить последним ───────────────────────────
eval "$(starship init zsh)"

# ── Local machine overrides (not tracked — personal hosts/paths/secrets) ──
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
