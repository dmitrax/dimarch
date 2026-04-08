#!/usr/bin/env bash
# =============================================================================
#  helpers.sh — DimArch OS shared library
# =============================================================================
#  Source this file at the top of every phase/app script:
#    source "$(dirname "$0")/../utils/helpers.sh"
#
#  Do NOT run this file directly.
# =============================================================================

# Guard against double-sourcing
[[ -n "${_DIMARCH_HELPERS:-}" ]] && return 0
_DIMARCH_HELPERS=1

# =============================================================================
#  Colors & symbols
# =============================================================================

_C_RESET='\033[0m'
_C_BOLD='\033[1m'
_C_DIM='\033[2m'

_C_WHITE='\033[97m'
_C_GREEN='\033[92m'
_C_CYAN='\033[96m'
_C_YELLOW='\033[93m'
_C_RED='\033[91m'
_C_GRAY='\033[90m'

_SYM_OK='✓'
_SYM_RUN='→'
_SYM_WARN='!'
_SYM_ERR='✗'
_SYM_DOT='◆'

# =============================================================================
#  Banner — shown once at the start of each phase script
# =============================================================================

# dimarch::banner "Phase 2 — CachyOS repositories"
dimarch::banner() {
    local title="${1:-DimArch OS}"
    local width=51

    echo ""
    echo -e "${_C_DIM}┌$( printf '─%.0s' $(seq 1 $width) )┐${_C_RESET}"
    echo -e "${_C_DIM}│${_C_RESET}  ${_C_BOLD}${_C_WHITE}${_SYM_DOT} DimArch OS${_C_RESET}$( printf ' %.0s' $(seq 1 $(( width - 13 ))) )${_C_DIM}│${_C_RESET}"
    echo -e "${_C_DIM}└$( printf '─%.0s' $(seq 1 $width) )┘${_C_RESET}"
    echo ""
    echo -e "  ${_C_BOLD}${_C_WHITE}━━━  ${title}  ━━━${_C_RESET}"
    echo ""
}

# =============================================================================
#  Section divider — lightweight separator between logical blocks
# =============================================================================

# dimarch::section "Installing packages"
dimarch::section() {
    local label="${1:-}"
    echo ""
    if [[ -n "$label" ]]; then
        echo -e "  ${_C_GRAY}┄┄┄  ${label}${_C_RESET}"
    else
        echo -e "  ${_C_GRAY}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${_C_RESET}"
    fi
    echo ""
}

# =============================================================================
#  Logging
# =============================================================================

# [✓]  success message
dimarch::ok() {
    echo -e "  ${_C_GREEN}[${_SYM_OK}]${_C_RESET}  $*"
}

# [→]  info / running
dimarch::info() {
    echo -e "  ${_C_CYAN}[${_SYM_RUN}]${_C_RESET}  $*"
}

# [!]  warning — non-fatal
dimarch::warn() {
    echo -e "  ${_C_YELLOW}[${_SYM_WARN}]${_C_RESET}  $*"
}

# [✗]  error — fatal, exits
dimarch::die() {
    echo -e "  ${_C_RED}[${_SYM_ERR}]${_C_RESET}  $*" >&2
    exit 1
}

# Aliases for convenience inside scripts
ok()   { dimarch::ok   "$@"; }
info() { dimarch::info "$@"; }
warn() { dimarch::warn "$@"; }
die()  { dimarch::die  "$@"; }

# =============================================================================
#  Confirmation prompt
# =============================================================================

# dimarch::confirm "Continue?"          → default No  [y/N]
# dimarch::confirm "Continue?" "y"      → default Yes [Y/n]
dimarch::confirm() {
    local msg="${1:-Continue?}"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        echo -ne "  ${_C_YELLOW}${msg} [Y/n]:${_C_RESET} "
        read -r _ans
        [[ -z "$_ans" || "${_ans,,}" == "y" ]]
    else
        echo -ne "  ${_C_YELLOW}${msg} [y/N]:${_C_RESET} "
        read -r _ans
        [[ "${_ans,,}" == "y" ]]
    fi
}

# =============================================================================
#  Package management
# =============================================================================

# Check if a pacman package is installed
# dimarch::is_installed git && echo "yes"
dimarch::is_installed() {
    pacman -Qq "$1" &>/dev/null
}

# Install packages via pacman (system packages)
# dimarch::pacman_install git curl wget
dimarch::pacman_install() {
    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if dimarch::is_installed "$pkg"; then
            info "${pkg} — already installed, skipping"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        return 0
    fi

    info "Installing: ${to_install[*]}"
    if pacman -S --noconfirm --needed "${to_install[@]}"; then
        for pkg in "${to_install[@]}"; do
            ok "${pkg} installed"
        done
    else
        die "pacman failed to install: ${to_install[*]}"
    fi
}

# Install packages via paru (AUR + official)
# dimarch::paru_install paru-bin hyprland
dimarch::paru_install() {
    command -v paru &>/dev/null \
        || die "paru not found — run 02-cachyos.sh first"

    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if dimarch::is_installed "$pkg"; then
            info "${pkg} — already installed, skipping"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        return 0
    fi

    info "Installing (AUR): ${to_install[*]}"
    if paru -S --noconfirm --needed "${to_install[@]}"; then
        for pkg in "${to_install[@]}"; do
            ok "${pkg} installed"
        done
    else
        die "paru failed to install: ${to_install[*]}"
    fi
}

# =============================================================================
#  Command checks
# =============================================================================

# Ensure a command exists before proceeding
# dimarch::require_cmd git curl stow
dimarch::require_cmd() {
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null \
            || die "Required command not found: ${cmd}"
    done
}

# =============================================================================
#  System checks
# =============================================================================

# Must run as root
dimarch::require_root() {
    [[ $EUID -eq 0 ]] \
        || die "This script must be run as root"
}

# Must NOT run as root (e.g. stow, user-level configs)
dimarch::require_user() {
    [[ $EUID -ne 0 ]] \
        || die "This script must NOT be run as root — run as your user"
}

# Check if running inside arch-chroot
dimarch::require_chroot() {
    # systemd-detect-virt returns "none" on bare metal,
    # inside chroot /proc/1/comm is typically "bash" not "systemd"
    local init_comm
    init_comm=$(cat /proc/1/comm 2>/dev/null || echo "unknown")
    if [[ "$init_comm" == "systemd" ]]; then
        die "This script must run inside arch-chroot, not on a booted system"
    fi
}

# =============================================================================
#  Service management
# =============================================================================

# Enable and start a systemd service
# dimarch::enable_service grub-btrfsd snapper-timeline.timer
dimarch::enable_service() {
    for svc in "$@"; do
        info "Enabling service: ${svc}"
        if systemctl enable --now "$svc" 2>/dev/null; then
            ok "${svc} enabled and started"
        else
            warn "Failed to start ${svc} — may need reboot"
            systemctl enable "$svc" 2>/dev/null || true
        fi
    done
}

# =============================================================================
#  Phase completion summary
# =============================================================================

# dimarch::done "Phase 2 complete" "Reboot to apply new kernel"
dimarch::done() {
    local title="${1:-Done}"
    local note="${2:-}"

    echo ""
    echo -e "  ${_C_GRAY}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${_C_RESET}"
    echo ""
    echo -e "  ${_C_GREEN}${_C_BOLD}${_SYM_OK}  ${title}${_C_RESET}"
    [[ -n "$note" ]] && echo -e "  ${_C_GRAY}   ${note}${_C_RESET}"
    echo ""
}
