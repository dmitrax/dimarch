#!/bin/bash
# =========================================================
# DimArch OS — Restore SDDM system config after updates
#
# Note: SDDM theme is maintained separately:
# https://github.com/dmitrax/dimarch-sddm-theme
# Install it first, then run this script.
# =========================================================

SRC_DIR="$(dirname "$0")"

echo "→ Applying sddm.conf..."
sudo cp "$SRC_DIR/sddm.conf" /etc/sddm.conf

echo "→ Applying Xsetup monitor config..."
sudo cp "$SRC_DIR/scripts/Xsetup" /usr/share/sddm/scripts/Xsetup
sudo chmod +x /usr/share/sddm/scripts/Xsetup

echo "→ Restarting SDDM..."
sudo systemctl restart sddm

echo "✓ Done."
