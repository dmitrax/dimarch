#!/usr/bin/env bash
# =============================================================================
# 01-btrfs-setup.sh — Post-archinstall BTRFS hardening
# =============================================================================
#
# Prerequisites:
#   1. Before archinstall: partition the disk manually with cfdisk/gdisk:
#        p1 — 4G    FAT32  → ESP (4 GB required for limine-snapper-sync)
#        p2 — 296G  (raw)  → archinstall will format as BTRFS + install here
#        p3 — 700G  (raw)  → fast data (this script formats it)
#   2. In archinstall: select p2 as root, BTRFS filesystem, Limine bootloader, no DE
#   3. After archinstall completes: arch-chroot /mnt → run this script
#
# What this script does:
#   • Detects system disk and root BTRFS partition automatically
#   • Verifies root subvolume is named '@' (required for fstab)
#   • Adds missing subvolumes: @home @snapshots @var_log @var_cache @var_tmp
#   • Asks for fast-data partition path → formats BTRFS + adds to fstab
#   • Regenerates /etc/fstab with all subvolumes and correct mount options
#   • Configures zram with RAM-aware sizing
#
# After this script: exit → umount -R /mnt → reboot
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${GREEN}[OK]${NC}   $*"; }
info()   { echo -e "${CYAN}[..]${NC}   $*"; }
warn()   { echo -e "${YELLOW}[!!]${NC}   $*"; }
die()    { echo -e "${RED}[ERR]${NC}  $*" >&2; exit 1; }

header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $*${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

confirm() {
    local msg="${1:-Continue?}"
    local default="${2:-n}"
    if [[ "$default" == "y" ]]; then
        echo -ne "${YELLOW}${msg} [Y/n]:${NC} "
        read -r ans
        [[ -z "$ans" || "${ans,,}" == "y" ]]
    else
        echo -ne "${YELLOW}${msg} [y/N]:${NC} "
        read -r ans
        [[ "${ans,,}" == "y" ]]
    fi
}

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Run as root inside arch-chroot /mnt"

# =============================================================================
# STEP 1 — Detect system disk and root partition
# =============================================================================
header "Step 1 — Detecting system disk"

ROOT_PART=$(findmnt -n -o SOURCE / | sed 's/\[.*//')
[[ -b "$ROOT_PART" ]] \
    || die "Cannot detect root partition. Are you inside arch-chroot /mnt?"

# Verify root partition is actually BTRFS
ROOT_FSTYPE=$(lsblk -no FSTYPE "$ROOT_PART")
[[ "$ROOT_FSTYPE" == "btrfs" ]] \
    || die "Root partition $ROOT_PART is not BTRFS (got: $ROOT_FSTYPE). Wrong partition?"

ROOT_DISK_NAME=$(lsblk -no PKNAME "$ROOT_PART" | head -1)
ROOT_DISK="/dev/${ROOT_DISK_NAME}"
[[ -b "$ROOT_DISK" ]] || die "Cannot find parent disk for $ROOT_PART"

# Detect ESP via findmnt (reliable — archinstall already mounted it)
EFI_PART=$(findmnt -n -o SOURCE /boot 2>/dev/null || true)
EFI_UUID=""
if [[ -b "$EFI_PART" ]]; then
    EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
    info "ESP detected:   ${BOLD}${EFI_PART}${NC} → /boot"
else
    warn "ESP not detected at /boot — will skip ESP entry in fstab"
fi

echo ""
info "System disk:    ${BOLD}${ROOT_DISK}${NC}"
info "Root partition: ${BOLD}${ROOT_PART}${NC} [btrfs]"
echo ""
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$ROOT_DISK"
echo ""

confirm "Is this correct?" "y" || die "Aborted."

# =============================================================================
# STEP 2 — Verify and create BTRFS subvolumes
# =============================================================================
header "Step 2 — Creating missing BTRFS subvolumes"

MOUNT_OPTS="defaults,noatime,compress=zstd:3,space_cache=v2"

BTRFS_TOP=$(mktemp -d)

# Trap to ensure cleanup on any exit
cleanup_btrfs_top() {
    umount "$BTRFS_TOP" 2>/dev/null || true
    rmdir "$BTRFS_TOP" 2>/dev/null || true
}
trap cleanup_btrfs_top EXIT

mount -o "noatime,compress=zstd:3,space_cache=v2" "$ROOT_PART" "$BTRFS_TOP"

echo ""
info "Existing subvolumes:"
btrfs subvolume list "$BTRFS_TOP"
echo ""

# Verify '@' subvolume exists — mandatory for fstab
if ! btrfs subvolume list "$BTRFS_TOP" | awk '{print $NF}' | grep -qx "@"; then
    die "Root subvolume '@' not found. Did archinstall use a different name?\n" \
        "       Check subvolume names above and update fstab manually."
fi
log "Root subvolume '@' confirmed."

# Create missing subvolumes
NEEDED=( @home @snapshots @var_log @var_cache @var_tmp )

for sv in "${NEEDED[@]}"; do
    if btrfs subvolume list "$BTRFS_TOP" | awk '{print $NF}' | grep -qx "$sv"; then
        info "Already exists, skipping: $sv"
    else
        btrfs subvolume create "${BTRFS_TOP}/${sv}"
        log "Created: $sv"
    fi
done

umount "$BTRFS_TOP"
rmdir "$BTRFS_TOP"
trap - EXIT

# =============================================================================
# STEP 3 — Fast-data partition
# =============================================================================
header "Step 3 — Fast-data partition (optional)"

echo ""
echo "  If you created a separate fast-data partition before archinstall"
echo "  (e.g. p3 on the same disk), enter its path now."
echo "  It will be formatted as BTRFS and mounted at /mnt/fast."
echo ""
echo "  Current block devices:"
lsblk -o NAME,SIZE,FSTYPE,LABEL
echo ""
echo -ne "  Fast-data partition path (e.g. /dev/nvme0n1p3), or Enter to skip: "
read -r FAST_PART

FAST_PART="${FAST_PART// /}"
SKIP_FAST=false

if [[ -z "$FAST_PART" ]]; then
    info "Skipping fast-data partition."
    SKIP_FAST=true
elif [[ ! -b "$FAST_PART" ]]; then
    warn "${FAST_PART} is not a valid block device — skipping."
    SKIP_FAST=true
elif [[ "$FAST_PART" == "$ROOT_PART" ]]; then
    die "Fast partition cannot be the same as root partition!"
elif [[ -n "$EFI_PART" && "$FAST_PART" == "$EFI_PART" ]]; then
    die "Fast partition cannot be the same as ESP!"
else
    FAST_FSTYPE=$(lsblk -no FSTYPE "$FAST_PART" 2>/dev/null || true)
    FAST_SIZE=$(lsblk -no SIZE "$FAST_PART")

    echo ""
    if [[ -n "$FAST_FSTYPE" ]]; then
        warn "Partition ${FAST_PART} (${FAST_SIZE}) has filesystem: ${FAST_FSTYPE}"
        warn "It will be WIPED and reformatted as BTRFS."
    else
        info "Partition ${FAST_PART} (${FAST_SIZE}) — no filesystem, will format as BTRFS."
    fi
    echo ""

    if ! confirm "Format ${FAST_PART} as BTRFS (label: dimarch-fast)?"; then
        info "Skipping fast-data partition."
        SKIP_FAST=true
    else
        info "Formatting ${FAST_PART}..."
        mkfs.btrfs -f -L "dimarch-fast" "$FAST_PART"
        log "Formatted: ${FAST_PART} → BTRFS [dimarch-fast]"

        FAST_TMP=$(mktemp -d)
        trap "umount '$FAST_TMP' 2>/dev/null; rmdir '$FAST_TMP' 2>/dev/null" EXIT
        mount "$FAST_PART" "$FAST_TMP"
        mkdir -p "${FAST_TMP}"/{winapps,models,comfyui}
        umount "$FAST_TMP"
        rmdir "$FAST_TMP"
        trap - EXIT
        log "Created directories: winapps/ models/ comfyui/"
    fi
fi

# =============================================================================
# STEP 4 — Regenerate /etc/fstab
# =============================================================================
header "Step 4 — Regenerating /etc/fstab"

OS_UUID=$(blkid -s UUID -o value "$ROOT_PART")

cp /etc/fstab /etc/fstab.archinstall.bak
info "Original fstab saved → /etc/fstab.archinstall.bak"

cat > /etc/fstab << EOF
# /etc/fstab — generated by 01-btrfs-setup.sh
# dimarch-os | $(date '+%Y-%m-%d')

EOF

if [[ -n "$EFI_UUID" ]]; then
    cat >> /etc/fstab << EOF
# ESP — Limine bootloader (kernels + initramfs + snapshot entries)
UUID=${EFI_UUID}  /boot  vfat  defaults,umask=0077  0 2

EOF
fi

cat >> /etc/fstab << EOF
# BTRFS — dimarch-os subvolumes
UUID=${OS_UUID}  /            btrfs  ${MOUNT_OPTS},subvol=@            0 0
UUID=${OS_UUID}  /home        btrfs  ${MOUNT_OPTS},subvol=@home        0 0
UUID=${OS_UUID}  /.snapshots  btrfs  ${MOUNT_OPTS},subvol=@snapshots   0 0
UUID=${OS_UUID}  /var/log     btrfs  ${MOUNT_OPTS},subvol=@var_log     0 0
UUID=${OS_UUID}  /var/cache   btrfs  ${MOUNT_OPTS},subvol=@var_cache   0 0
UUID=${OS_UUID}  /var/tmp     btrfs  ${MOUNT_OPTS},subvol=@var_tmp     0 0
EOF

if [[ "$SKIP_FAST" == false ]]; then
    FAST_UUID=$(blkid -s UUID -o value "$FAST_PART")
    cat >> /etc/fstab << EOF

# BTRFS — dimarch-fast
UUID=${FAST_UUID}  /mnt/fast  btrfs  ${MOUNT_OPTS}  0 0
EOF
fi

log "fstab written."
echo ""
info "New /etc/fstab:"
echo "──────────────────────────────────────────────────"
cat /etc/fstab
echo "──────────────────────────────────────────────────"

# =============================================================================
# STEP 5 — Configure zram (RAM-aware sizing)
# =============================================================================
header "Step 5 — Configuring zram"

if ! pacman -Qq zram-generator &>/dev/null; then
    info "Installing zram-generator..."
    pacman -Sy --noconfirm --needed zram-generator
fi

TOTAL_RAM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)

#   ≤  8G → zram = RAM        (small RAM, needs maximum swap capacity)
#   ≤ 16G → zram = RAM / 2   (reasonable balance)
#   > 16G → zram = RAM / 4   (OOM protection only, RAM is sufficient)
if (( TOTAL_RAM_GB <= 8 )); then
    ZRAM_SIZE="ram"
    ZRAM_NOTE="${TOTAL_RAM_GB}G RAM → zram = ${TOTAL_RAM_GB}G (~$(( TOTAL_RAM_GB * 2 ))G effective)"
elif (( TOTAL_RAM_GB <= 16 )); then
    ZRAM_SIZE="ram / 2"
    ZRAM_NOTE="${TOTAL_RAM_GB}G RAM → zram = $(( TOTAL_RAM_GB / 2 ))G (~${TOTAL_RAM_GB}G effective)"
else
    ZRAM_SIZE="ram / 4"
    ZRAM_NOTE="${TOTAL_RAM_GB}G RAM → zram = $(( TOTAL_RAM_GB / 4 ))G (OOM protection)"
fi

cat > /etc/systemd/zram-generator.conf << EOF
# zram swap — configured by 01-btrfs-setup.sh
# ${ZRAM_NOTE}
[zram0]
zram-size = ${ZRAM_SIZE}
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

log "zram configured: ${ZRAM_NOTE}"

# =============================================================================
# STEP 6 — Create mountpoint directories
# =============================================================================
header "Step 6 — Creating mountpoint directories"

mkdir -p /.snapshots
mkdir -p /var/{log,cache,tmp}
[[ "$SKIP_FAST" == false ]] && mkdir -p /mnt/fast

log "Mountpoints ready."

# =============================================================================
# Done
# =============================================================================
header "All done"

echo ""
echo -e "${GREEN}${BOLD}Setup complete.${NC}"
echo ""
echo -e "  ${CYAN}Root partition:${NC}  $ROOT_PART"
echo -e "  ${CYAN}Subvolumes:${NC}      @ @home @snapshots @var_log @var_cache @var_tmp"
[[ -n "$EFI_PART" ]] && \
    echo -e "  ${CYAN}ESP:${NC}             $EFI_PART → /boot"
[[ "$SKIP_FAST" == false ]] && \
    echo -e "  ${CYAN}Fast partition:${NC}  $FAST_PART → /mnt/fast"
echo -e "  ${CYAN}zram:${NC}            ${ZRAM_NOTE}"
echo ""
echo -e "${CYAN}Disk layout:${NC}"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$ROOT_DISK"
echo ""
echo -e "${BOLD}${YELLOW}Next steps:${NC}"
echo ""
echo -e "  1. exit"
echo -e "  2. umount -R /mnt"
echo -e "  3. reboot"
echo ""
echo -e "${BOLD}${CYAN}After reboot:${NC}"
echo ""
echo -e "  pacman -S git"
echo -e "  git clone https://github.com/dmitrax/dimarch"
echo -e "  cd dimarch && ./install.sh"
echo ""
