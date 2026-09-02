# DimArch OS — Package List

What the numbered install phases actually install. The source of truth is the scripts
themselves (`install/phases/03-base.sh`, `install/phases/05-hyprland.sh`) — this page
mirrors them for reading, and any disagreement means the page is stale, not the script.

Packages of DimArch's own components (`dimarch-theme`, `dimarch-hyprland`, …) are not
listed here: they ship from the `[dimarch]` repository, see `docs/ROADMAP.md` §4.3.

## Hyprland core
| Package | Purpose |
|---|---|
| hyprland | Wayland compositor |
| hyprpaper | Wallpaper daemon |
| hyprlock | Lock screen |
| hypridle | Idle daemon |
| xdg-desktop-portal-hyprland | Screenshots, screen sharing |
| xdg-desktop-portal-gtk | Portal backend for GTK apps |
| uwsm | Runs Hyprland as a systemd user session |
| wlopm | Output power management (disabled on this GPU, see `docs/hardware.md`) |
| hyprpolkitagent | Authentication agent (systemd user service) |
| hyprland-per-window-layout | Per-window keyboard layout (AUR) |

## Bar, launcher, notifications
| Package | Purpose |
|---|---|
| waybar-git | Top bar (the `-git` build is deliberate — see the vault note on the libcava ABI break) |
| rofi-wayland | App launcher; also powers the link router's browser picker (`docs/link-router.md`) |
| swaync | Notification centre, replaced mako |
| swayosd | On-screen display for volume, mic, CapsLock, ScrollLock |
| libnotify | Desktop notification client library |

## Files
| Package | Purpose |
|---|---|
| thunar | GUI file manager |
| thunar-volman | Removable media handling inside Thunar |
| thunar-archive-plugin | Extract/compress from the context menu |
| gvfs | Trash and network locations — Thunar breaks silently without it |
| tumbler | Thumbnail service |
| glycin | HEIF / JPEG XL / SVG thumbnails for tumbler |
| ffmpegthumbnailer | Video thumbnails |
| yazi | Terminal file manager (alias `y`) |
| udiskie | Automount daemon |
| gparted | Partition editor |

Dolphin and the whole KIO stack were removed on 2026-07-09 — see
`decision-thunar-instead-of-dolphin-because-no-kio-dependency` in the vault.

## Media and documents
| Package | Purpose |
|---|---|
| swayimg | Image viewer (default), Wayland-native, Lua-configured |
| mpv + mpv-mpris | Video player (default) |
| mpv-uosc | QuickTime-style OSC theme for mpv (chaotic-aur) |
| papers | PDF / ePub / DjVu viewer (default) |
| zathura + zathura-pdf-mupdf | Keyboard-driven PDF alternative, not the default |
| mousepad | Plain text editor (default) |
| gst-plugins-{good,bad,ugly}, gst-libav | GStreamer codecs |

## Screenshots and clipboard
| Package | Purpose |
|---|---|
| grim | Wayland screen capture |
| slurp | Area selection |
| satty | Screenshot annotation |
| hyprpicker | Colour picker (`Super+P`) |
| wl-clipboard | Wayland clipboard |
| cliphist | Clipboard history (`Super+V`) |

## Terminal and shell
| Package | Purpose |
|---|---|
| ghostty | GPU terminal emulator |
| zsh | Shell |
| starship | Shell prompt |
| eza, bat, fd, ripgrep, fzf, zoxide, tree | Command-line tooling |
| git-delta | Diff viewer for git |
| lazygit | Terminal git UI |
| tealdeer | `tldr` client |
| man-db, man-pages | Manual pages |

## Audio
| Package | Purpose |
|---|---|
| pipewire, pipewire-pulse, pipewire-alsa, pipewire-jack | Audio stack |
| wireplumber | PipeWire session manager |
| pavucontrol | Volume mixer |

## Fonts
| Package | Purpose |
|---|---|
| ttf-jetbrains-mono-nerd | Terminal and code font |
| nerd-fonts-inter | UI font |
| noto-fonts, noto-fonts-emoji, ttf-liberation | Coverage and emoji |

## Qt and GTK integration
| Package | Purpose |
|---|---|
| qt5-wayland, qt6-wayland | Native Wayland for Qt apps |
| qt5ct, qt6ct | Qt theme engine (`QT_QPA_PLATFORMTHEME=qt6ct`) |

## System, hardware, boot
| Package | Purpose |
|---|---|
| chwd | CachyOS hardware detection — drivers by PCI ID instead of hardcoded lists |
| bluez, bluez-utils, blueman | Bluetooth |
| ufw | Firewall |
| plymouth + plymouth-theme-monoarch-refined | Boot splash |
| os-prober | Windows dual-boot detection (config-gated, off by default) |
| btop, nvtop, lm_sensors, smartmontools, lsof | Monitoring and diagnostics |
| ntfs-3g, exfatprogs, fuse-exfat | Foreign filesystems |
| unrar, unzip, unace, p7zip, lrzip, squashfs-tools, file-roller | Archives |
| wget, aria2, openssh, bind, traceroute | Network tools |
| gnome-keyring | Password and secrets storage |
| socat, python, xorg-xhost | Scripting and compatibility helpers |
| git | Version control |
| linux-firmware-qlogic, aic94xx-firmware, ast-firmware, upd72020x-fw, wd719x-firmware | Firmware pulled in by `base-devel` expectations (AUR) |

## Snapshots (only on a BTRFS install)
| Package | Purpose |
|---|---|
| snapper | Filesystem snapshots |
| snap-pac | Snapshot before every pacman transaction |
| grub-btrfs, grub-btrfsd | Boot into a snapshot from the GRUB menu |

The filesystem choice for a clean install is currently being reconsidered — if the target
is not BTRFS, this whole section goes away with `install/phases/04-snapper.sh`.

## Optional apps
Not part of the numbered phases and never run by the orchestrator — each is a standalone
script under `install/apps/`: Enpass, herdr, mise, Obsidian, dimarch-scribe, VS Code,
ZapZap. See `docs/ROADMAP.md` Hard Rule 7.
