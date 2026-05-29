# Troubleshooting — DimArch OS

---

## Oversized fonts in GTK apps (Thunar, etc.)

**Symptom:** GTK applications (Thunar, settings dialogs, etc.) display oversized fonts
in Hyprland, while the same apps look normal in XFCE.

**Root cause:** A leftover `~/.config/environment.d/wayland.conf` from a previous XFCE
session was loaded by systemd at login — before Hyprland starts — and contained:

```ini
GDK_DPI_SCALE=1.5          # forces 150% font scaling on all GTK apps
XDG_CURRENT_DESKTOP=XFCE   # wrong desktop identity
XCURSOR_SIZE=36             # conflicts with Hyprland env.lua (24)
WAYLAND_DISPLAY=wayland-1  # hardcoded, unsafe
```

`GDK_DPI_SCALE=1.5` combined with Hyprland's own compositor scaling for the 4K monitor
resulted in fonts being scaled twice.

**Fix:**

```bash
rm ~/.config/environment.d/wayland.conf
```

All required environment variables are already correctly defined in
`~/.config/hypr/hyprland/env.lua`, including `GDK_DPI_SCALE=1`.

**Lesson:** After migrating from another DE, check `~/.config/environment.d/` for
leftover configs that may conflict with Hyprland's environment setup.
