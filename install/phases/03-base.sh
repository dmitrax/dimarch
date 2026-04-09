#!/usr/bin/env bash
# =============================================================================
#  03-base.sh — Base system configuration and utilities
# =============================================================================
#  Run as root after 02-cachyos.sh and reboot into the new kernel.
#
#  What this script does:
#    1.  Localization — locale.gen, localectl, vconsole.conf
#    2.  Bluetooth — bluez, blueman, bluez-utils
#    3.  OOM killer — systemd-oomd
#    4.  Firewall — ufw with sensible defaults
#    5.  Firmware — missing firmware packages for common hardware
#    6.  Archives — unrar, unzip, p7zip, lrzip, unace, squashfs-tools
#    7.  Codecs — gstreamer plugins, ffmpegthumbnailer
#    8.  Filesystems — ntfs-3g, exfatprogs, fuse-exfat
#    9.  Network utils — wget, aria2, openssh
#    10. Monitoring — btop, nvtop, lm_sensors, smartmontools
#    11. File utils — tree, fd, ripgrep, fzf, eza, zoxide
#    12. Documentation — man-db, man-pages
#    13. Audio — pipewire, pipewire-pulse, wireplumber, pavucontrol
#    14. Base fonts — noto-fonts, noto-fonts-emoji, ttf-liberation
#    15. Plymouth — boot splash animation + theme
#    16. Dual boot — optional RTC sync for Windows coexistence
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/helpers.sh"

# =============================================================================
dimarch::banner "Phase 3 — Base system configuration"
# =============================================================================

dimarch::require_root

# =============================================================================
#  STEP 1 — Localization
# =============================================================================
dimarch::section "Localization"

LOCALE_GEN="/etc/locale.gen"
LOCALE_CONF="/etc/locale.conf"
VCONSOLE_CONF="/etc/vconsole.conf"

echo ""
echo -e "  ${_C_BOLD}${_C_WHITE}Configure system locale${_C_RESET}"
echo ""
echo -e "  ${_C_CYAN}1)${_C_RESET} en_US.UTF-8   ${_C_GRAY}[default]${_C_RESET}"
echo -e "  ${_C_CYAN}2)${_C_RESET} ru_RU.UTF-8"
echo -e "  ${_C_CYAN}3)${_C_RESET} ru_UA.UTF-8"
echo -e "  ${_C_CYAN}4)${_C_RESET} uk_UA.UTF-8"
echo -e "  ${_C_CYAN}5)${_C_RESET} Enter custom locale"
echo ""
echo -ne "  ${_C_YELLOW}Your choice [1-5, default 1]:${_C_RESET} "
read -r LOCALE_CHOICE

case "${LOCALE_CHOICE}" in
    2) SYSTEM_LOCALE="ru_RU.UTF-8" ;;
    3) SYSTEM_LOCALE="ru_UA.UTF-8" ;;
    4) SYSTEM_LOCALE="uk_UA.UTF-8" ;;
    5)
        echo -ne "  ${_C_YELLOW}Enter locale (e.g. de_DE.UTF-8):${_C_RESET} "
        read -r SYSTEM_LOCALE
        ;;
    *) SYSTEM_LOCALE="en_US.UTF-8" ;;
esac

info "Selected locale: ${SYSTEM_LOCALE}"

# Uncomment locale in locale.gen
if grep -q "^${SYSTEM_LOCALE}" "$LOCALE_GEN"; then
    info "${SYSTEM_LOCALE} already uncommented in locale.gen"
else
    sed -i "s/^#\(${SYSTEM_LOCALE}\)/\1/" "$LOCALE_GEN"
    ok "Uncommented ${SYSTEM_LOCALE} in locale.gen"
fi

# Always ensure en_US.UTF-8 is present (needed by many tools)
if ! grep -q "^en_US.UTF-8" "$LOCALE_GEN"; then
    sed -i 's/^#\(en_US.UTF-8\)/\1/' "$LOCALE_GEN"
    ok "Uncommented en_US.UTF-8 in locale.gen (required by many tools)"
fi

info "Generating locales..."
locale-gen
ok "Locales generated"

# Set system locale
localectl set-locale "LANG=${SYSTEM_LOCALE}"
ok "System locale set to ${SYSTEM_LOCALE}"

# Virtual console font + keymap (Cyrillic support in TTY)
if [[ -f "$VCONSOLE_CONF" ]] && grep -q "FONT=cyr-sun16" "$VCONSOLE_CONF"; then
    info "vconsole.conf already configured — skipping"
else
    info "Configuring virtual console (Cyrillic font + keymap)..."
    cat > "$VCONSOLE_CONF" << 'EOF'
# /etc/vconsole.conf — configured by 03-base.sh (dimarch-os)
FONT=cyr-sun16
KEYMAP=ru
EOF
    ok "vconsole.conf configured: font=cyr-sun16, keymap=ru"
fi

# =============================================================================
#  STEP 2 — Bluetooth
# =============================================================================
dimarch::section "Bluetooth"

dimarch::pacman_install bluez bluez-utils blueman

info "Loading btusb kernel module..."
modprobe btusb 2>/dev/null || warn "btusb module not available — skipping"

dimarch::enable_service bluetooth
ok "Bluetooth ready"

# =============================================================================
#  STEP 3 — OOM killer
# =============================================================================
dimarch::section "OOM killer"

info "Enabling systemd-oomd (Out-Of-Memory daemon)..."
dimarch::enable_service systemd-oomd
ok "systemd-oomd active"

# =============================================================================
#  STEP 4 — Firewall (ufw)
# =============================================================================
dimarch::section "Firewall (ufw)"

dimarch::pacman_install ufw

dimarch::enable_service ufw

# Apply sensible defaults only if ufw is inactive (first run)
if ! ufw status | grep -q "Status: active"; then
    info "Applying default firewall rules..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw enable
    ok "ufw enabled: deny incoming, allow outgoing"
else
    info "ufw already active — skipping default rules"
fi

# =============================================================================
#  STEP 5 — Firmware
# =============================================================================
dimarch::section "Missing firmware packages"

info "Installing common missing firmware..."
dimarch::paru_install \
    linux-firmware-qlogic \
    aic94xx-firmware \
    ast-firmware \
    upd72020x-fw \
    wd719x-firmware

ok "Firmware packages installed"

# =============================================================================
#  STEP 6 — Archives
# =============================================================================
dimarch::section "Archive utilities"

dimarch::pacman_install \
    unrar \
    unzip \
    unace \
    p7zip \
    lrzip \
    squashfs-tools \
    file-roller

ok "Archive utilities installed"

# =============================================================================
#  STEP 7 — Codecs
# =============================================================================
dimarch::section "Media codecs"

dimarch::pacman_install \
    gst-libav \
    gst-plugins-ugly \
    gst-plugins-good \
    gst-plugins-bad \
    ffmpegthumbnailer

ok "Codecs installed"

# Clear thumbnail cache so new thumbnailers take effect
THUMB_FAIL="${HOME}/.cache/thumbnails/fail"
if [[ -d "$THUMB_FAIL" ]]; then
    rm -rf "$THUMB_FAIL"
    ok "Thumbnail fail cache cleared"
fi

# =============================================================================
#  STEP 8 — Filesystems
# =============================================================================
dimarch::section "Filesystem support"

dimarch::pacman_install \
    ntfs-3g \
    exfatprogs \
    fuse-exfat

ok "NTFS, exFAT filesystem support installed"

# =============================================================================
#  STEP 9 — Network utilities
# =============================================================================
dimarch::section "Network utilities"

dimarch::pacman_install \
    wget \
    aria2 \
    openssh \
    bind \
    traceroute

ok "Network utilities installed"

# =============================================================================
#  STEP 10 — System monitoring
# =============================================================================
dimarch::section "System monitoring"

dimarch::pacman_install \
    btop \
    nvtop \
    lm_sensors \
    smartmontools

# Run sensors-detect non-interactively to load sensor modules
info "Detecting hardware sensors..."
sensors-detect --auto > /dev/null 2>&1 || true
ok "Monitoring tools installed"

# =============================================================================
#  STEP 11 — File utilities
# =============================================================================
dimarch::section "File utilities"

dimarch::pacman_install \
    tree \
    fd \
    ripgrep \
    fzf \
    eza \
    zoxide

ok "File utilities installed"

# =============================================================================
#  STEP 12 — Documentation
# =============================================================================
dimarch::section "Documentation"

dimarch::pacman_install \
    man-db \
    man-pages

ok "man pages installed"

# =============================================================================
#  STEP 13 — Audio (PipeWire)
# =============================================================================
dimarch::section "Audio (PipeWire)"

dimarch::pacman_install \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol

# Enable wireplumber as user service (must run as actual user, not root)
REALUSER="${SUDO_USER:-}"
if [[ -n "$REALUSER" ]]; then
    info "Enabling wireplumber for user ${REALUSER}..."
    sudo -u "$REALUSER" systemctl --user enable --now wireplumber 2>/dev/null \
        || warn "wireplumber user service will start automatically on login"
else
    warn "Cannot enable wireplumber — run as sudo to detect user"
    warn "Run manually: systemctl --user enable --now wireplumber"
fi

ok "PipeWire audio stack installed"

# =============================================================================
#  STEP 14 — Base fonts
# =============================================================================
dimarch::section "Base fonts"

dimarch::pacman_install \
    noto-fonts \
    noto-fonts-emoji \
    ttf-liberation

ok "Base fonts installed"

# =============================================================================
#  STEP 15 — Plymouth (boot splash)
# =============================================================================
dimarch::section "Plymouth boot splash"

dimarch::pacman_install plymouth

# Add plymouth hook to mkinitcpio (after udev)
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

if grep -q "plymouth" "$MKINITCPIO_CONF"; then
    info "Plymouth hook already in mkinitcpio.conf — skipping"
else
    info "Adding plymouth hook to mkinitcpio.conf..."
    sed -i 's/\(HOOKS=.*udev\)/\1 plymouth/' "$MKINITCPIO_CONF"
    ok "Plymouth hook added after udev"
fi

# Add quiet splash to GRUB cmdline
GRUB_DEFAULT_CONF="/etc/default/grub"

if grep -q "quiet splash" "$GRUB_DEFAULT_CONF"; then
    info "quiet splash already in GRUB cmdline — skipping"
else
    info "Adding quiet splash to GRUB_CMDLINE_LINUX_DEFAULT..."
    sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 quiet splash"/' \
        "$GRUB_DEFAULT_CONF"
    ok "quiet splash added to GRUB cmdline"
fi

# Install Plymouth theme
info "Installing Plymouth theme: monoarch-refined..."
dimarch::paru_install plymouth-theme-monoarch-refined

info "Setting Plymouth theme..."
plymouth-set-default-theme -R monoarch-refined
ok "Plymouth theme set: monoarch-refined"

# Rebuild initramfs and GRUB
info "Rebuilding initramfs (mkinitcpio -P)..."
mkinitcpio -P
ok "initramfs rebuilt"

info "Updating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg
ok "GRUB config updated"

# =============================================================================
#  STEP 16 — Dual boot (optional)
# =============================================================================
dimarch::section "Dual boot"

echo ""
echo -e "  ${_C_BOLD}${_C_WHITE}Windows dual boot detected?${_C_RESET}"
echo -e "  ${_C_GRAY}If you dual boot with Windows, the system clocks may be out of sync.${_C_RESET}"
echo -e "  ${_C_GRAY}This sets hardware clock to local time (Windows compatible).${_C_RESET}"
echo ""

if dimarch::confirm "Fix clock sync for Windows dual boot?"; then
    timedatectl set-local-rtc 1
    ok "Hardware clock set to local time (Windows compatible)"
    warn "If you stop dual booting, run: timedatectl set-local-rtc 0"
else
    info "Skipping dual boot clock fix"
fi

# =============================================================================
dimarch::done \
    "Phase 3 complete" \
    "Run 04-snapper.sh next"
# =============================================================================
