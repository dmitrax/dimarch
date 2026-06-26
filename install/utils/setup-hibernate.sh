#!/usr/bin/env bash
# =============================================================================
#  setup-hibernate.sh — configure hibernate for DimArch OS (BUG-01 fix)
# =============================================================================
#
#  Run as root. Idempotent — safe to re-run.
#
#  What this script does:
#    1. Reads swapfile_path from /etc/dimarch.conf (or repo dimarch.conf)
#    2. Auto-detects RAM → swapfile size = RAM + 2 GB
#    3. Auto-detects filesystem type (ext4 / btrfs) for correct swapfile setup
#    4. Creates and activates swapfile if not present
#    5. Adds swapfile entry to /etc/fstab
#    6. Adds 'resume' hook to mkinitcpio.conf HOOKS (before 'filesystems')
#    7. Calculates resume_offset (filefrag for ext4, btrfs inspect for btrfs)
#    8. Adds resume=UUID=... resume_offset=... to GRUB_CMDLINE_LINUX_DEFAULT
#    9. Rebuilds initramfs (mkinitcpio -P) and regenerates GRUB config
#   10. Deploys dimarch-sleep to /usr/local/bin/
#
#  Usage:
#    sudo ./setup-hibernate.sh
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

dimarch::require_root
dimarch::banner "setup-hibernate — BUG-01 fix"

# =============================================================================
#  Load dimarch.conf
# =============================================================================

dimarch::section "Configuration"

DIMARCH_CONF="${DIMARCH_CONF:-/etc/dimarch.conf}"

if [[ ! -f "$DIMARCH_CONF" ]]; then
    REPO_CONF="${SCRIPT_DIR}/../../dimarch.conf"
    if [[ -f "$REPO_CONF" ]]; then
        info "Deploying dimarch.conf → /etc/dimarch.conf"
        install -m 644 "$REPO_CONF" /etc/dimarch.conf
        DIMARCH_CONF=/etc/dimarch.conf
    else
        die "dimarch.conf not found.\n  Copy dimarch.conf.example → dimarch.conf, fill in your values, then re-run."
    fi
fi

ok "Config: ${DIMARCH_CONF}"

SWAPFILE="$(dimarch::conf_get power swapfile_path "$DIMARCH_CONF")"
SWAPFILE="${SWAPFILE:-/home/.swapfile}"

# =============================================================================
#  Size detection
# =============================================================================

dimarch::section "Size detection"

RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$(( (RAM_KB + 1024*1024 - 1) / (1024*1024) ))
SWAP_GB=$(( RAM_GB + 2 ))

info "RAM:       ${RAM_GB} GB"
info "Swapfile:  ${SWAP_GB} GB  (RAM + 2 GB)"
info "Path:      ${SWAPFILE}"

SWAP_DIR="$(dirname "$SWAPFILE")"
FS_TYPE=$(findmnt -no FSTYPE -T "$SWAP_DIR")
info "Filesystem: ${FS_TYPE}"

# =============================================================================
#  Create swapfile
# =============================================================================

dimarch::section "Swapfile"

if [[ -f "$SWAPFILE" ]]; then
    ok "Swapfile already exists — skipping creation"
else
    info "Creating ${SWAP_GB}G swapfile..."

    if [[ "$FS_TYPE" == "btrfs" ]]; then
        # BTRFS: must disable CoW and compression before allocating
        truncate -s 0 "$SWAPFILE"
        chattr +C "$SWAPFILE"
        btrfs property set "$SWAPFILE" compression none
        dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( SWAP_GB * 1024 )) status=progress conv=fdatasync
    else
        fallocate -l "${SWAP_GB}G" "$SWAPFILE"
    fi

    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    ok "Swapfile created"
fi

if swapon --show | grep -qF "$SWAPFILE"; then
    ok "Swapfile already active"
else
    swapon "$SWAPFILE"
    ok "Swapfile activated"
fi

# =============================================================================
#  /etc/fstab
# =============================================================================

dimarch::section "fstab"

if grep -qF "$SWAPFILE" /etc/fstab; then
    ok "fstab entry already present"
else
    printf '%s none swap defaults 0 0\n' "$SWAPFILE" >> /etc/fstab
    ok "fstab entry added"
fi

# =============================================================================
#  resume_offset
# =============================================================================

dimarch::section "resume_offset"

if [[ "$FS_TYPE" == "btrfs" ]]; then
    RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r "$SWAPFILE")
else
    RESUME_OFFSET=$(filefrag -v "$SWAPFILE" 2>/dev/null \
        | awk '$1 ~ /^0:/ { gsub(/\./, "", $4); print $4; exit }')
fi

SWAP_UUID=$(findmnt -no UUID -T "$SWAPFILE")

info "Partition UUID:  ${SWAP_UUID}"
info "resume_offset:   ${RESUME_OFFSET}"

# =============================================================================
#  mkinitcpio
# =============================================================================

dimarch::section "mkinitcpio"

MKINITCPIO_CONF=/etc/mkinitcpio.conf

if grep -qE '\bresume\b' "$MKINITCPIO_CONF"; then
    ok "resume hook already in mkinitcpio.conf"
else
    # Insert 'resume' immediately before 'filesystems' in the HOOKS line
    sed -i 's/\(HOOKS=([^)]*\)\bfilesystems\b/\1resume filesystems/' "$MKINITCPIO_CONF"

    if grep -qE '\bresume\b' "$MKINITCPIO_CONF"; then
        ok "resume hook added"
    else
        die "Failed to insert resume hook — check HOOKS line in ${MKINITCPIO_CONF}"
    fi
fi

# =============================================================================
#  GRUB
# =============================================================================

dimarch::section "GRUB"

GRUB_CONF=/etc/default/grub
RESUME_PARAMS="resume=UUID=${SWAP_UUID} resume_offset=${RESUME_OFFSET}"

if grep -q 'resume=UUID=' "$GRUB_CONF"; then
    # Update existing params in place
    sed -i \
        -e "s|resume=UUID=[^[:space:]\"]*|resume=UUID=${SWAP_UUID}|g" \
        -e "s|resume_offset=[^[:space:]\"]*|resume_offset=${RESUME_OFFSET}|g" \
        "$GRUB_CONF"
    ok "GRUB resume params updated"
else
    # Append to GRUB_CMDLINE_LINUX_DEFAULT
    sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"|\1 ${RESUME_PARAMS}\"|" "$GRUB_CONF"
    ok "GRUB resume params added"
fi

info "Running mkinitcpio -P..."
mkinitcpio -P

info "Running grub-mkconfig..."
grub-mkconfig -o /boot/grub/grub.cfg

ok "GRUB config regenerated"

# =============================================================================
#  Deploy dimarch-sleep
# =============================================================================

dimarch::section "dimarch-sleep"

install -m 755 "${SCRIPT_DIR}/dimarch-sleep" /usr/local/bin/dimarch-sleep
ok "dimarch-sleep → /usr/local/bin/dimarch-sleep"

# =============================================================================
#  sudoers — allow wheel to hibernate without password
# =============================================================================

dimarch::section "sudoers"

# systemctl hibernate fails via logind CanHibernate() on systemd 261 (ENOENT).
# dimarch-sleep bypasses logind by calling 'sudo systemctl start hibernate.target'.
# Grant only the specific desktop user, not the entire wheel group.
DESKTOP_USER=$(dimarch::conf_get system username "$DIMARCH_CONF")
[[ -z "$DESKTOP_USER" ]] && die "dimarch.conf [system] username is not set."

sed "s/__USERNAME__/${DESKTOP_USER}/" \
    "${SCRIPT_DIR}/dimarch-hibernate-nopasswd.sudoers" \
    > /etc/sudoers.d/dimarch-hibernate
chmod 440 /etc/sudoers.d/dimarch-hibernate
ok "sudoers: ${DESKTOP_USER} NOPASSWD: systemctl start hibernate.target"

# =============================================================================
#  Deploy dimarch.conf if not already at /etc/
# =============================================================================

if [[ "$DIMARCH_CONF" != "/etc/dimarch.conf" ]] && [[ ! -f /etc/dimarch.conf ]]; then
    install -m 644 "$DIMARCH_CONF" /etc/dimarch.conf
    ok "dimarch.conf → /etc/dimarch.conf"
fi

# =============================================================================
#  Done
# =============================================================================

dimarch::done \
    "Hibernate configured" \
    "Test: sudo systemctl start hibernate.target   |   Via idle: set sleep_mode=hibernate in dimarch.conf"

echo ""
info "Swapfile:    ${SWAPFILE}  (${SWAP_GB}G, ${FS_TYPE})"
info "resume=      UUID=${SWAP_UUID}"
info "offset=      ${RESUME_OFFSET}"
info "sleep_mode in dimarch.conf: set to 'hibernate' to activate"
info "Note: uses 'sudo systemctl start hibernate.target' — logind CanHibernate() broken in systemd 261"
echo ""
