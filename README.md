# DimArch OS — Sage

Modern system. Old soul.

> ⚠️ **Work in progress** — actively developed, not yet ready for general use.

Some desktops are named after plants.  
MATE showed us how a desktop should feel.  
Sage remembers.

Floating windows. Proper panels. Right-click on the desktop.  
Arch Linux + Hyprland — built for 2026, rooted in tradition.

For those who remember the golden era of GNOME 2 and MATE.

---

## Philosophy

This is not just a rice. It's a classic desktop experience rebuilt on a modern stack.

- **Floating-only** — windows behave like windows, not tiles
- **Two panels** — top system bar + bottom window list, just like GNOME 2/MATE
- **Right-click on the desktop** — because that's how it should work
- **One command install** — clone it, run `install.sh`, your system is ready

---

## Stack

| Component | Choice |
|---|---|
| Base | Arch Linux via `archinstall` |
| Kernel | CachyOS LTS + BORE |
| Compositor | Hyprland (Wayland) |
| Theme | Sage — calm, clean, rooted |
| Bootloader | GRUB |
| Filesystem | BTRFS with snapshots |

Dual-booting with Windows? Set `enable_windows_dualboot = true` under `[boot]` in your
`dimarch.conf` before running `install.sh` — GRUB will detect it via `os-prober`. Off by
default.

---

## Install

```bash
# Pre-reboot (inside arch-chroot)
curl -O https://raw.githubusercontent.com/dmitrax/dimarch/main/install/phases/01-btrfs-setup.sh
chmod +x 01-btrfs-setup.sh && ./01-btrfs-setup.sh

# After reboot
pacman -S git
git clone https://github.com/dmitrax/dimarch
cd dimarch && ./install.sh
```

---

*DimArch OS — Personal Arch Linux setup by Dmitrax*
