#!/usr/bin/env bash
# =============================================================================
#  03-base.sh — Base system configuration and utilities
# =============================================================================
#  Run as root after 02-cachyos.sh and reboot into the new kernel.
#
#  What this script does:
#    1.  Localization — locale.gen, localectl, vconsole.conf
#    2.  Bluetooth — bluez, blueman, bluez-utils
#    3.  OOM killer — systemd-oomd; coredump limits — /etc/systemd/coredump.conf.d
#    4.  Firewall — ufw with sensible defaults
#    5.  Hardware auto-detection — chwd (GPU/network/power-management drivers,
#        any vendor: AMD/NVIDIA/Intel — required for a public repo that must
#        install cleanly on hardware other than the maintainer's own RX 580)
#    6.  Firmware — missing firmware packages for common hardware
#    7.  Archives — unrar, unzip, p7zip, lrzip, unace, squashfs-tools
#    8.  Codecs — gstreamer plugins, ffmpegthumbnailer
#    9.  Filesystems — ntfs-3g, exfatprogs, fuse-exfat
#    10. Network utils — wget, aria2, openssh
#    11. Monitoring — btop, nvtop, lm_sensors, smartmontools, lsof
#    12. File utils — tree, fd, ripgrep, fzf, eza, zoxide
#    13. Documentation — man-db, man-pages
#    14. Audio — pipewire, pipewire-pulse, wireplumber, pavucontrol
#    15. Base fonts — noto-fonts, noto-fonts-emoji, ttf-liberation
#    16. Desktop utils — cliphist, wl-clipboard, udiskie
#    17. Plymouth — boot splash animation + theme (GRUB + amdgpu early KMS)
#    18. Dual boot — optional RTC sync + os-prober GRUB detection for Windows
#        coexistence (dimarch.conf [boot] enable_windows_dualboot, off by default)
#    19. dimarchctl + companion utils (dimarch-monitor, dimarch-sleep,
#        dimarch-hypridle-gen) — deployed to /usr/local/bin/
#    20. WireGuard VPN — optional, invokes setup-wireguard.sh
#        (dimarch.conf [vpn] enable, off by default)
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
#  STEP 3 — OOM killer + coredump limits
# =============================================================================
dimarch::section "OOM killer and coredump limits"

info "Enabling systemd-oomd (Out-Of-Memory daemon)..."
dimarch::enable_service systemd-oomd
ok "systemd-oomd active"

# Unbounded coredump processing is the other way this machine runs out of
# memory, and systemd-oomd does not cover it: systemd-coredump runs as its own
# transient service and can peak in the tens of gigabytes writing out and
# parsing a large Electron dump (measured: 22.4 GB / ~2.5 min, twice, freezing
# the desktop). The drop-in caps that. See the file's own header for the
# numbers and for why ProcessSizeMax is the only knob that helps here.
install -d -m 755 -o root -g root /etc/systemd/coredump.conf.d
install -m 644 -o root -g root \
    "${SCRIPT_DIR}/../utils/dimarch-coredump.conf" \
    /etc/systemd/coredump.conf.d/dimarch.conf
ok "coredump limits installed (Storage=none, ProcessSizeMax=2G)"

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
#  STEP 5 — Hardware auto-detection (chwd)
# =============================================================================
dimarch::section "Hardware auto-detection (chwd)"

# chwd (CachyOS Hardware Detection) reads PCI/USB device IDs and installs the
# matching driver profile — GPU (nvidia/amd/intel/nouveau), network (broadcom-wl,
# marvell-wifi), power management (intel-lpmd), VM guest tools. This is what
# keeps the installer hardware-agnostic: dimarch is a public repo and must not
# assume every installer is running on the maintainer's RX 580 — chwd picks the
# right mesa/vulkan/firmware packages for whatever GPU and NIC are actually
# present. `-a`/`--autoconfigure` with no value defaults to "any" (all classes).
# AI SDK profiles (CUDA/ROCm) are opt-in via a separate --ai_sdk flag and are
# deliberately NOT passed here — RX 580 (gfx803) isn't in chwd's ROCm
# gc_versions list anyway, and the project's AI stack is Vulkan/llama-cpp-vulkan,
# not ROCm (see rx580-gpu-compute-stack decision).
dimarch::pacman_install chwd

info "Running chwd -a (autoconfigure all detected hardware)..."
chwd -a
ok "chwd hardware auto-detection complete"

# =============================================================================
#  STEP 6 — Firmware
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
#  STEP 7 — Archives
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
#  STEP 8 — Codecs
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
#  STEP 9 — Filesystems
# =============================================================================
dimarch::section "Filesystem support"

dimarch::pacman_install \
    ntfs-3g \
    exfatprogs \
    fuse-exfat

ok "NTFS, exFAT filesystem support installed"

# =============================================================================
#  STEP 10 — Network utilities
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
#  STEP 11 — System monitoring
# =============================================================================
dimarch::section "System monitoring"

dimarch::pacman_install \
    btop \
    nvtop \
    lm_sensors \
    smartmontools \
    lsof

# Run sensors-detect non-interactively to load sensor modules
info "Detecting hardware sensors..."
sensors-detect --auto > /dev/null 2>&1 || true
ok "Monitoring tools installed"

# =============================================================================
#  STEP 12 — File utilities
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
#  STEP 13 — Documentation
# =============================================================================
dimarch::section "Documentation"

dimarch::pacman_install \
    man-db \
    man-pages

ok "man pages installed"

# =============================================================================
#  STEP 14 — Audio (PipeWire)
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
#  STEP 15 — Base fonts
# =============================================================================
dimarch::section "Base fonts"

dimarch::pacman_install \
    noto-fonts \
    noto-fonts-emoji \
    ttf-liberation

ok "Base fonts installed"

# =============================================================================
#  STEP 16 — Desktop utilities
# =============================================================================
dimarch::section "Desktop utilities"

# Clipboard history manager.
# wl-clipboard provides wl-paste/wl-copy — required by cliphist.
# cliphist watches clipboard and stores history in ~/.cache/cliphist/db.
# History is persistent across reboots (SQLite, up to 750 entries by default).
# Keybind Super+V opens rofi picker — configured in dotfiles/hypr/keybinds.lua.
dimarch::pacman_install \
    cliphist \
    wl-clipboard

ok "Clipboard manager installed (cliphist + wl-clipboard)"

# Auto-mount daemon for removable media (USB drives, SD cards).
# Replaces the automounting that GNOME/KDE/XFCE handle out of the box.
# Runs as user service, integrates with Dolphin via udisks2.
# Tray icon shows mounted volumes — enabled via execs.lua.
dimarch::pacman_install udiskie

ok "Auto-mount daemon installed (udiskie)"

# Polkit authentication agent (hyprpolkitagent — hyprwm's own agent, recommended
# by wiki.hypr.land over the unmaintained polkit-gnome).
# Required for GUI privilege escalation dialogs. Without this, GUI apps silently
# fail when requesting root permissions.
# Ships its own systemd user service (WantedBy=graphical-session.target) —
# enable it instead of exec'ing the binary from execs.lua.
dimarch::pacman_install hyprpolkitagent

if [[ -n "$REALUSER" ]]; then
    info "Enabling hyprpolkitagent for user ${REALUSER}..."
    sudo -u "$REALUSER" systemctl --user enable --now hyprpolkitagent 2>/dev/null \
        || warn "hyprpolkitagent user service will start automatically on login"
else
    warn "Cannot enable hyprpolkitagent — run as sudo to detect user"
    warn "Run manually: systemctl --user enable --now hyprpolkitagent"
fi

ok "Polkit agent installed (hyprpolkitagent)"

# XDG desktop portals — required for:
#   - Screen sharing in Firefox/Chromium
#   - File picker dialogs in sandboxed apps
#   - Screenshot portal (used by some apps)
# xdg-desktop-portal-hyprland: Hyprland-specific portal backend
# xdg-desktop-portal-gtk: fallback for GTK file pickers
dimarch::pacman_install \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk

ok "XDG desktop portals installed"

# Qt theming — native Wayland backend + theme engine. dotfiles/hypr's env.lua
# sets QT_QPA_PLATFORMTHEME=qt6ct, which silently no-ops (Qt apps fall back to
# unthemed Fusion style) without qt6ct actually installed. Found running live
# without either pair 2026-07-08 (must-have-hyprland-utilities-audit).
dimarch::pacman_install \
    qt5-wayland \
    qt6-wayland \
    qt5ct \
    qt6ct

ok "Qt theming installed"

# =============================================================================
#  STEP 17 — Plymouth (boot splash)
# =============================================================================
dimarch::section "Plymouth boot splash"

# Install Plymouth
dimarch::pacman_install plymouth

MKINITCPIO_CONF="/etc/mkinitcpio.conf"

# Add amdgpu to MODULES for early KMS (required for Plymouth on RX 580 / Polaris).
# Early KMS initializes the GPU before the display manager starts,
# allowing Plymouth to render the splash on the GPU framebuffer.
if grep -qE "^MODULES=.*amdgpu" "$MKINITCPIO_CONF"; then
    info "amdgpu already in mkinitcpio MODULES — skipping"
else
    info "Adding amdgpu to mkinitcpio MODULES (early KMS for Plymouth)..."
    sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 amdgpu)/' "$MKINITCPIO_CONF"
    # Handle empty MODULES=() case
    sed -i 's/^MODULES=( amdgpu)/MODULES=(amdgpu)/' "$MKINITCPIO_CONF"
    ok "amdgpu added to MODULES"
fi

# Add plymouth hook to mkinitcpio HOOKS (must come after udev).
# This embeds Plymouth into the initramfs so it shows during boot.
if grep -q "plymouth" "$MKINITCPIO_CONF"; then
    info "Plymouth hook already in mkinitcpio.conf — skipping"
else
    info "Adding plymouth hook after udev in mkinitcpio.conf..."
    sed -i 's/\(HOOKS=.*udev\)/\1 plymouth/' "$MKINITCPIO_CONF"
    ok "Plymouth hook added after udev"
fi

# Add quiet splash to the GRUB kernel cmdline.
# GRUB config lives at /etc/default/grub (GRUB_CMDLINE_LINUX_DEFAULT).
GRUB_DEFAULT_CONF="/etc/default/grub"

if [[ ! -f "$GRUB_DEFAULT_CONF" ]]; then
    warn "GRUB config not found at ${GRUB_DEFAULT_CONF} — skipping cmdline patch"
    warn "Add 'quiet splash' to GRUB_CMDLINE_LINUX_DEFAULT manually in ${GRUB_DEFAULT_CONF}"
else
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash' "$GRUB_DEFAULT_CONF"; then
        info "quiet splash already in GRUB cmdline — skipping"
    else
        info "Adding quiet splash to GRUB_CMDLINE_LINUX_DEFAULT..."
        sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ quiet splash"/' "$GRUB_DEFAULT_CONF"
        info "Regenerating GRUB configuration..."
        grub-mkconfig -o /boot/grub/grub.cfg
        ok "quiet splash added to GRUB cmdline"
    fi
fi

# =============================================================================
#  Optional — Windows dual-boot detection (os-prober)
# =============================================================================
# Off by default. Enable only if Windows is actually installed on this
# machine: dimarch.conf [boot] enable_windows_dualboot = true

DIMARCH_CONF="${DIMARCH_CONF:-/etc/dimarch.conf}"
# `|| true`: conf_get returns 1 if $DIMARCH_CONF doesn't exist yet (true on a
# real fresh install — no phase script deploys /etc/dimarch.conf before this
# point). Without it, `set -e` aborts the whole script here silently. Found
# 2026-07-24 wiring the VPN block below, which hits the same pattern.
ENABLE_DUALBOOT="$(dimarch::conf_get boot enable_windows_dualboot "$DIMARCH_CONF" || true)"
ENABLE_DUALBOOT="${ENABLE_DUALBOOT:-false}"

if [[ "$ENABLE_DUALBOOT" == "true" ]]; then
    dimarch::section "Windows dual-boot (os-prober)"

    dimarch::pacman_install os-prober
    ok "os-prober installed"

    # GRUB >= 2.06 disables os-prober by default for security reasons — it
    # takes an explicit GRUB_DISABLE_OS_PROBER=false, not just the absence
    # of "=true". Arch's stock /etc/default/grub ships the line commented
    # out, so handle commented, uncommented, and missing cases alike.
    if grep -q '^GRUB_DISABLE_OS_PROBER=false' "$GRUB_DEFAULT_CONF"; then
        info "GRUB_DISABLE_OS_PROBER already false — os-prober enabled"
    elif grep -q '^[[:space:]]*#\?GRUB_DISABLE_OS_PROBER=' "$GRUB_DEFAULT_CONF"; then
        info "Enabling os-prober (GRUB_DISABLE_OS_PROBER=false)..."
        sed -i 's/^[[:space:]]*#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_DEFAULT_CONF"
    else
        info "Enabling os-prober (adding GRUB_DISABLE_OS_PROBER=false)..."
        echo 'GRUB_DISABLE_OS_PROBER=false' >> "$GRUB_DEFAULT_CONF"
    fi

    info "Regenerating GRUB configuration with os-prober..."
    grub-mkconfig -o /boot/grub/grub.cfg
    ok "GRUB config updated — Windows entries (if found) added to boot menu"
else
    info "enable_windows_dualboot=false in ${DIMARCH_CONF} — skipping os-prober"
fi

# Install Plymouth theme (placeholder until dimarch-theme provides one).
# dimarch-theme will ship a custom Sage-branded Plymouth theme in the future.
info "Installing Plymouth theme: monoarch-refined..."
dimarch::paru_install plymouth-theme-monoarch-refined

info "Setting Plymouth theme..."
plymouth-set-default-theme -R monoarch-refined
ok "Plymouth theme set: monoarch-refined"

# Rebuild initramfs to include Plymouth + amdgpu early KMS
info "Rebuilding initramfs (mkinitcpio -P)..."
mkinitcpio -P
ok "initramfs rebuilt"

# =============================================================================
#  STEP 18 — Dual boot (optional)
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
#  STEP 19 — dimarchctl + companion utils
# =============================================================================
dimarch::section "dimarchctl"

# System tooling, not a user dotfile — hence 03-base.sh, not 06-dotfiles.sh.
# hypridle.conf's regeneration path (dimarchctl power apply) and zsh's
# vpn/vpnoff/vpnst/wg-ui aliases are dead on a from-scratch install without
# these on $PATH. Found running live with zero phase-script coverage,
# 2026-07-20 (adhoc-packages-pending-install-script-wiring).
install -m 755 -o root -g root "${SCRIPT_DIR}/../utils/dimarchctl" /usr/local/bin/dimarchctl
install -m 755 -o root -g root "${SCRIPT_DIR}/../utils/dimarch-monitor" /usr/local/bin/dimarch-monitor
install -m 755 -o root -g root "${SCRIPT_DIR}/../utils/dimarch-sleep" /usr/local/bin/dimarch-sleep
install -m 755 -o root -g root "${SCRIPT_DIR}/../utils/dimarch-hypridle-gen" /usr/local/bin/dimarch-hypridle-gen

ok "dimarchctl + companion utils installed to /usr/local/bin/"

# =============================================================================
#  STEP 20 — WireGuard VPN (optional)
# =============================================================================
# Off by default. Enable via dimarch.conf [vpn] enable = true — same
# config-gating pattern as Windows dual-boot above. setup-wireguard.sh is
# self-contained and idempotent (packages, NetworkManager, config import,
# autoconnect off), so this just invokes it rather than duplicating its logic.

ENABLE_VPN="$(dimarch::conf_get vpn enable "$DIMARCH_CONF" || true)"
ENABLE_VPN="${ENABLE_VPN:-false}"

if [[ "$ENABLE_VPN" == "true" ]]; then
    dimarch::section "WireGuard VPN"
    "${SCRIPT_DIR}/../utils/setup-wireguard.sh"
else
    info "[vpn] enable=false in ${DIMARCH_CONF} — skipping WireGuard setup"
fi

# =============================================================================
dimarch::done \
    "Phase 3 complete" \
    "Run 04-snapper.sh next"
# =============================================================================
