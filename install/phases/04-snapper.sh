#!/usr/bin/env bash
# =============================================================================
#  04-snapper.sh — BTRFS snapshots
# =============================================================================
#  Run as root after 03-base.sh.
#
#  What this script does:
#    1. Installs snapper, grub-btrfs, snap-pac
#    2. Creates snapper config for root (/)
#    3. Sets snapshot retention limits
#    4. Enables snapper timers (timeline + cleanup)
#    5. Enables grub-btrfsd (auto-updates GRUB menu with snapshots)
#    6. Creates first manual snapshot — "base install"
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/helpers.sh"

# =============================================================================
dimarch::banner "Phase 4 — BTRFS snapshots"
# =============================================================================

dimarch::require_root

# =============================================================================
#  STEP 1 — Install packages
# =============================================================================
dimarch::section "Installing packages"

dimarch::pacman_install snapper grub-btrfs snap-pac

ok "snapper, grub-btrfs, snap-pac installed"

# =============================================================================
#  STEP 2 — Create snapper config for root
# =============================================================================
dimarch::section "Snapper configuration"

if snapper list-configs | grep -q "^root"; then
    info "Snapper root config already exists — skipping creation"
else
    # snapper create-config requires /.snapshots to NOT exist as a directory.
    # We already have @snapshots BTRFS subvolume mounted there via fstab
    # (created in 01-btrfs-setup.sh). The subvolume itself stays on disk —
    # we only temporarily unmount it so snapper can create its config file
    # and recreate the /.snapshots directory entry.
    if mountpoint -q /.snapshots; then
        info "Temporarily unmounting /.snapshots (subvolume stays on disk)..."
        umount /.snapshots
    fi

    # Remove the now-empty mountpoint dir so snapper can create it fresh
    # This does NOT delete the @snapshots subvolume — only the mount dir
    [[ -d /.snapshots ]] && rmdir /.snapshots 2>/dev/null || true

    info "Creating snapper config for root..."
    snapper -c root create-config /
    ok "Snapper config created"

    # Remount @snapshots subvolume back onto /.snapshots using fstab entry
    # Same subvolume, same UUID, same mount options — nothing changed on disk
    if grep -q "\.snapshots" /etc/fstab; then
        mount /.snapshots
        ok "/.snapshots remounted — @snapshots subvolume back in place"
    fi
fi

# =============================================================================
#  STEP 3 — Configure retention limits
# =============================================================================
dimarch::section "Snapshot retention limits"

SNAPPER_CONF="/etc/snapper/configs/root"

[[ -f "$SNAPPER_CONF" ]] || die "Snapper config not found: ${SNAPPER_CONF}"

info "Setting retention limits..."

# Helper to set a value in snapper config
snapper_set() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" "$SNAPPER_CONF"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$SNAPPER_CONF"
    else
        echo "${key}=\"${value}\"" >> "$SNAPPER_CONF"
    fi
}

# Timeline limits
snapper_set "TIMELINE_CREATE"          "yes"
snapper_set "TIMELINE_CLEANUP"         "yes"
snapper_set "TIMELINE_LIMIT_HOURLY"    "3"
snapper_set "TIMELINE_LIMIT_DAILY"     "5"
snapper_set "TIMELINE_LIMIT_WEEKLY"    "2"
snapper_set "TIMELINE_LIMIT_MONTHLY"   "2"
snapper_set "TIMELINE_LIMIT_YEARLY"    "0"

# snap-pac (pre/post) limits
snapper_set "NUMBER_CLEANUP"           "yes"
snapper_set "NUMBER_LIMIT"             "10"
snapper_set "NUMBER_LIMIT_IMPORTANT"   "5"

ok "Retention limits set:"
echo ""
echo -e "  ${_C_GRAY}  timeline: 3 hourly · 5 daily · 2 weekly · 2 monthly · 0 yearly${_C_RESET}"
echo -e "  ${_C_GRAY}  snap-pac: 10 pre/post pairs max${_C_RESET}"
echo ""

# =============================================================================
#  STEP 4 — Enable snapper timers
# =============================================================================
dimarch::section "Enabling snapper timers"

# snapper-timeline — creates snapshots on schedule
dimarch::enable_service snapper-timeline.timer

# snapper-cleanup — removes old snapshots per retention limits
dimarch::enable_service snapper-cleanup.timer

ok "Snapper timers active"

# =============================================================================
#  STEP 5 — Enable grub-btrfsd
# =============================================================================
dimarch::section "grub-btrfs"

# grub-btrfsd watches /.snapshots and auto-regenerates GRUB menu
dimarch::enable_service grub-btrfsd

# Regenerate GRUB config now so snapshots appear immediately
info "Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg
ok "GRUB menu updated — snapshots visible at boot"

# =============================================================================
#  STEP 6 — First snapshot
# =============================================================================
dimarch::section "Creating first snapshot"

info "Creating base install snapshot..."
snapper -c root create \
    --type single \
    --cleanup-algorithm number \
    --description "base install — dimarch-os"

ok "First snapshot created"

# Show snapshot list
echo ""
info "Current snapshots:"
echo ""
snapper -c root list
echo ""

# =============================================================================
dimarch::done \
    "Phase 4 complete" \
    "Run 05-gpu.sh next"
# =============================================================================
