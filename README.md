# DimArch OS — Sage

Modern system. Old soul.

> ⚠️ **Work in progress** — actively developed, not yet installable end-to-end.
> See [**ROADMAP.md**](docs/ROADMAP.md) for exactly what's done, what's in
> progress, and what's still a plan.

Some desktops are named after plants.
MATE showed us how a desktop should feel.
Sage remembers.

Floating windows, proper panels, a calm and legible desktop —
Arch Linux + Hyprland, built for 2026, rooted in tradition.

For those who remember the golden era of GNOME 2 and MATE.

---

## Status

DimArch runs daily on its author's own hardware, but the installer isn't a
single command yet. Core stability (crash-free suspend/hibernate, health
checks, monitor handling) is done. The Hyprland shell — panel, launcher,
notifications, file manager, default apps, theming — is largely built and
scripted. The bottom taskbar and desktop right-click menu described below
are the **vision**, not shipped yet.

**→ [Full component-by-component status: docs/ROADMAP.md](docs/ROADMAP.md)**

---

## Philosophy

This is not just a rice. It's a classic desktop experience rebuilt on a modern stack.

- **Floating-only** — windows behave like windows, not tiles
- **Top panel today, MATE-style bottom window list planned** — see Roadmap Phase 2
- **Right-click on the desktop** — planned, not built yet (Phase 2 backlog)
- **One command install** — the goal: clone it, run `install.sh`, your system is ready

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
`dimarch.conf` before running the installer — GRUB will detect it via `os-prober`. Off by
default.

---

## Install

There's no single `install.sh` yet — see [ROADMAP.md](docs/ROADMAP.md) for
why and what's left. Until then, the numbered phase scripts under
`install/phases/` are run by hand, in order, on a fresh Arch install:

```bash
# Pre-reboot (inside arch-chroot)
curl -O https://raw.githubusercontent.com/dmitrax/dimarch/main/install/phases/01-btrfs-setup.sh
chmod +x 01-btrfs-setup.sh && ./01-btrfs-setup.sh

# After reboot
pacman -S git
git clone https://github.com/dmitrax/dimarch
cd dimarch
sudo install/phases/02-cachyos.sh
sudo install/phases/03-base.sh
sudo install/phases/04-snapper.sh
sudo install/phases/05-hyprland.sh
sudo install/phases/06-dotfiles.sh
```

Phases `07-theme.sh`, `08-browser.sh`, and the `install.sh` orchestrator
that ties all of this into one command don't exist yet.

Optional, install-on-demand apps (AI stack, WinApps VM, individual GUI
apps) live under `install/apps/*.sh` and are never run automatically —
see ROADMAP's "Optional Apps" section.

---

## Related repos

- [dimarch-theme](https://github.com/dmitrax/dimarch-theme) — Sage GTK/icon/color theme
- [dimarch-sddm-theme](https://github.com/dmitrax/dimarch-sddm-theme) — SDDM login theme
- [dimarch-taskbar](https://github.com/dmitrax/dimarch-taskbar) — bottom panel (in development)

---

*DimArch OS — Personal Arch Linux setup by Dmitrax*
