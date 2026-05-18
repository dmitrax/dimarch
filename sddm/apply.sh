#!/bin/bash
THEME_DIR="/usr/share/sddm/themes/corners"
SRC_DIR="$(dirname "$0")/corners"

echo "→ Applying custom SDDM theme files..."
sudo cp "$SRC_DIR/theme.conf" "$THEME_DIR/"
sudo cp "$SRC_DIR/components/LoginPanel.qml" "$THEME_DIR/components/"
echo "✓ Done. Restart SDDM: sudo systemctl restart sddm"
