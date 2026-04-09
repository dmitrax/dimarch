#!/usr/bin/env bash
# =============================================================================
#  02-cachyos.sh — CachyOS repositories + kernel + paru + pacman tuning
# =============================================================================
#  Run as root after first reboot into the installed system.
#
#  What this script does:
#    1. Adds CachyOS repositories (pacman.conf)
#    2. Installs CachyOS keyring and mirrorlist
#    3. Asks which CachyOS kernel to install: LTS (default) or current
#       The stock Arch kernel (linux) is kept as a fallback — never removed
#    4. Configures GRUB: remember last selected kernel (GRUB_SAVEDEFAULT)
#    5. Installs paru (AUR helper) + configures paru.conf + bat/devtools
#    6. Configures reflector — fastest mirrors, auto-refresh weekly
#    7. Configures paccache — automatic package cache cleanup
#    8. Installs bash-completion
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/helpers.sh"

# =============================================================================
dimarch::banner "Phase 2 — CachyOS repos, kernel & pacman tuning"
# =============================================================================

dimarch::require_root

# =============================================================================
#  STEP 1 — Add CachyOS repositories
# =============================================================================
dimarch::section "CachyOS repositories"

PACMAN_CONF="/etc/pacman.conf"

if grep -q "\[cachyos\]" "$PACMAN_CONF"; then
    info "CachyOS repos already present in pacman.conf — skipping"
else
    info "Adding CachyOS repositories to pacman.conf..."

    # CachyOS repo signing key
    if ! pacman-key --list-keys F3B607488DB35A47 &>/dev/null; then
        info "Importing CachyOS signing key..."
        pacman-key --recv-keys F3B607488DB35A47
        pacman-key --lsign-key F3B607488DB35A47
        ok "Signing key imported and locally signed"
    else
        info "Signing key already present — skipping"
    fi

    # Install CachyOS keyring and mirrorlist first
    info "Installing cachyos-keyring and cachyos-mirrorlist..."
    pacman -U --noconfirm \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-18-1-any.pkg.tar.zst' \
        'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-18-1-any.pkg.tar.zst'
    ok "CachyOS keyring and mirrorlist installed"

    # Append CachyOS repo blocks to pacman.conf
    cat >> "$PACMAN_CONF" << 'EOF'

# ── CachyOS repositories ──────────────────────────────────────────────────────
[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist
EOF

    ok "CachyOS repos added to pacman.conf"
fi

info "Syncing package databases..."
pacman -Sy
ok "Package databases updated"

# =============================================================================
#  STEP 2 — Kernel selection
# =============================================================================
dimarch::section "Kernel selection"

echo ""
echo -e "  ${_C_WHITE}${_C_BOLD}Choose a CachyOS kernel to install:${_C_RESET}"
echo ""
echo -e "  ${_C_CYAN}1)${_C_RESET} ${_C_BOLD}linux-cachyos-lts${_C_RESET}  — Long-term support  ${_C_GRAY}[default, recommended]${_C_RESET}"
echo -e "     ${_C_GRAY}Stable, well-tested. Best for daily driver workstations.${_C_RESET}"
echo ""
echo -e "  ${_C_CYAN}2)${_C_RESET} ${_C_BOLD}linux-cachyos${_C_RESET}      — Latest current kernel"
echo -e "     ${_C_GRAY}Newest features and hardware support. Less conservative.${_C_RESET}"
echo ""
echo -e "  ${_C_GRAY}The stock Arch kernel (linux) will remain installed as a fallback.${_C_RESET}"
echo ""
echo -ne "  ${_C_YELLOW}Your choice [1/2, default 1]:${_C_RESET} "
read -r KERNEL_CHOICE

case "${KERNEL_CHOICE}" in
    2)
        KERNEL_PKG="linux-cachyos"
        KERNEL_HEADERS="linux-cachyos-headers"
        KERNEL_LABEL="linux-cachyos (current)"
        ;;
    *)
        KERNEL_PKG="linux-cachyos-lts"
        KERNEL_HEADERS="linux-cachyos-lts-headers"
        KERNEL_LABEL="linux-cachyos-lts (LTS)"
        ;;
esac

echo ""
info "Selected: ${KERNEL_LABEL}"
echo ""

# =============================================================================
#  STEP 3 — Install selected CachyOS kernel
# =============================================================================
dimarch::section "Installing kernel"

if dimarch::is_installed "$KERNEL_PKG"; then
    info "${KERNEL_PKG} already installed — skipping"
else
    info "Installing ${KERNEL_PKG} and ${KERNEL_HEADERS}..."
    pacman -S --noconfirm --needed "$KERNEL_PKG" "$KERNEL_HEADERS"
    ok "${KERNEL_LABEL} installed"
fi

# Verify stock kernel is still present (safety check)
if dimarch::is_installed linux; then
    ok "Stock Arch kernel (linux) present — kept as fallback"
else
    warn "Stock Arch kernel (linux) not found — installing for safety..."
    pacman -S --noconfirm --needed linux linux-headers
    ok "Stock Arch kernel installed as fallback"
fi

# =============================================================================
#  STEP 4 — Configure GRUB
# =============================================================================
dimarch::section "Configuring GRUB"

GRUB_DEFAULT_CONF="/etc/default/grub"

# Enable GRUB_SAVEDEFAULT — remembers last selected kernel across reboots
if grep -q "GRUB_SAVEDEFAULT=true" "$GRUB_DEFAULT_CONF"; then
    info "GRUB_SAVEDEFAULT already set — skipping"
else
    info "Enabling GRUB_SAVEDEFAULT (remember last selected kernel)..."
    # Set GRUB_DEFAULT=saved (required for GRUB_SAVEDEFAULT to work)
    sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' "$GRUB_DEFAULT_CONF"
    # Add GRUB_SAVEDEFAULT if not present
    if grep -q "^GRUB_SAVEDEFAULT" "$GRUB_DEFAULT_CONF"; then
        sed -i 's/^GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' "$GRUB_DEFAULT_CONF"
    else
        sed -i '/^GRUB_DEFAULT=/a GRUB_SAVEDEFAULT=true' "$GRUB_DEFAULT_CONF"
    fi
    ok "GRUB_DEFAULT=saved + GRUB_SAVEDEFAULT=true"
fi

if command -v grub-mkconfig &>/dev/null; then
    info "Regenerating GRUB configuration..."
    grub-mkconfig -o /boot/grub/grub.cfg
    ok "GRUB config updated — all kernels visible in boot menu"
else
    warn "grub-mkconfig not found — skipping"
    warn "Run manually: grub-mkconfig -o /boot/grub/grub.cfg"
fi

# =============================================================================
#  STEP 5 — Install paru (AUR helper)
# =============================================================================
dimarch::section "Installing paru (AUR helper)"

if command -v paru &>/dev/null; then
    info "paru already installed — skipping"
else
    # paru requires base-devel and git
    info "Installing build dependencies..."
    pacman -S --noconfirm --needed base-devel git

    # Build paru from AUR as a temporary non-root user if needed
    # paru-bin is the prebuilt binary — simpler and faster
    TMPDIR="$(mktemp -d)"
    BUILDUSER="${SUDO_USER:-}"

    if [[ -n "$BUILDUSER" ]]; then
        # Running via sudo — build as the actual user
        info "Building paru-bin as ${BUILDUSER}..."
        chown -R "$BUILDUSER":"$BUILDUSER" "$TMPDIR"
        cd "$TMPDIR"
        sudo -u "$BUILDUSER" git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        sudo -u "$BUILDUSER" makepkg -si --noconfirm
    else
        # Running as root directly — create a temp build user
        info "Creating temporary build user for AUR..."
        useradd -m -G wheel _dimarch_build 2>/dev/null || true
        echo "_dimarch_build ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/_dimarch_build

        chown -R _dimarch_build:_dimarch_build "$TMPDIR"
        cd "$TMPDIR"
        sudo -u _dimarch_build git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        sudo -u _dimarch_build makepkg -si --noconfirm

        # Cleanup temp user
        userdel -r _dimarch_build 2>/dev/null || true
        rm -f /etc/sudoers.d/_dimarch_build
    fi

    rm -rf "$TMPDIR"
    ok "paru installed"
fi

# Verify paru works
dimarch::require_cmd paru
ok "paru is ready"

# Configure paru.conf
PARU_CONF="/etc/paru.conf"

if grep -q "dimarch" "$PARU_CONF" 2>/dev/null; then
    info "paru.conf already configured — skipping"
else
    info "Configuring paru.conf..."
    sed -i \
        -e 's/^#BottomUp/BottomUp/' \
        -e 's/^#SudoLoop/SudoLoop/' \
        -e 's/^#CombinedUpgrade/CombinedUpgrade/' \
        -e 's/^#UpgradeMenu/UpgradeMenu/' \
        -e 's/^#NewsOnUpgrade/NewsOnUpgrade/' \
        "$PARU_CONF"
    # SkipReview — skip PKGBUILD review prompt (add only if not present)
    grep -q "^SkipReview" "$PARU_CONF" \
        || echo "SkipReview" >> "$PARU_CONF"
    # Mark as configured by dimarch
    echo "# configured by dimarch-os 02-cachyos.sh" >> "$PARU_CONF"
    ok "paru.conf configured: BottomUp, SudoLoop, CombinedUpgrade, SkipReview"
fi

# paru optional deps: bat (colored PKGBUILD printing), devtools (chroot builds)
info "Installing paru optional dependencies..."
dimarch::pacman_install bat devtools

# Initialize paru package database
info "Initializing paru database..."
paru --gendb
ok "paru database initialized"

# =============================================================================
#  STEP 6 — Reflector (fastest mirrors)
# =============================================================================
dimarch::section "Configuring reflector"

dimarch::pacman_install reflector rsync curl

REFLECTOR_CONF="/etc/xdg/reflector/reflector.conf"

if grep -q "dimarch" "$REFLECTOR_CONF" 2>/dev/null; then
    info "reflector.conf already configured — skipping"
else
    info "Writing reflector.conf..."
    cat > "$REFLECTOR_CONF" << 'EOF'
# reflector.conf — configured by 02-cachyos.sh (dimarch-os)
# Docs: man reflector

# Save results to mirrorlist
--save /etc/pacman.d/mirrorlist

# Protocol
--protocol https

# Country — use mirrors from these countries (fastest for most EU/global)
--country Germany,France,Netherlands,Poland

# Use the 20 most recently synchronized mirrors
--latest 20

# Sort by download rate
--sort rate
EOF
    ok "reflector.conf written"
fi

info "Running reflector to update mirrorlist (this may take a moment)..."
systemctl start reflector
ok "Mirrorlist updated"

info "Enabling reflector.timer (weekly auto-refresh)..."
systemctl enable --now reflector.timer
ok "reflector.timer enabled"

# =============================================================================
#  STEP 7 — Paccache (automatic package cache cleanup)
# =============================================================================
dimarch::section "Configuring paccache"

dimarch::pacman_install pacman-contrib

# Override paccache.service to keep only 1 version + remove uninstalled
PACCACHE_OVERRIDE="/etc/systemd/system/paccache.service.d/override.conf"

if [[ -f "$PACCACHE_OVERRIDE" ]]; then
    info "paccache override already exists — skipping"
else
    info "Configuring paccache to keep 1 version per package..."
    mkdir -p "$(dirname "$PACCACHE_OVERRIDE")"
    cat > "$PACCACHE_OVERRIDE" << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/paccache -rk1 ; /usr/bin/paccache -ruk0
EOF
    ok "paccache configured: keep 1 installed version, remove all uninstalled"
fi

info "Enabling paccache.timer (weekly auto-cleanup)..."
systemctl enable --now paccache.timer
ok "paccache.timer enabled"

# =============================================================================
#  STEP 8 — bash-completion
# =============================================================================
dimarch::section "Base shell utilities"

dimarch::pacman_install bash-completion
ok "bash-completion installed"

# =============================================================================
dimarch::done \
    "Phase 2 complete" \
    "Reboot to load the new kernel, then run 03-base.sh"
# =============================================================================
