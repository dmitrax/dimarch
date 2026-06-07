#!/bin/bash
source "$(dirname "$0")/../utils/helpers.sh"

dimarch::section "Hyprland Stack"

# ── Hyprland core ────────────────────────────────────────
pacman -Sy --needed \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    uwsm \
    wlopm

# ── Panel & launcher ─────────────────────────────────────
pacman -S --needed \
    rofi-wayland \
    swayosd \
    mako \
    libnotify \
    waybar-git

# ── File manager ─────────────────────────────────────────
pacman -S --needed \
    dolphin \
    kio \
    kio-extras \
    kio-admin \
    ffmpegthumbs

# ── Screenshot ───────────────────────────────────────────
pacman -S --needed \
    grim \
    slurp \
    satty \
    wl-clipboard

# ── Terminal & shell ─────────────────────────────────────
pacman -S --needed \
    ghostty \
    zsh \
    starship \
    ttf-jetbrains-mono-nerd \
    inter-font

# ── Terminal tools ────────────────────────────────────────
pacman -S --needed \
    eza \
    bat \
    fzf \
    zoxide \
    git-delta \
    tealdeer \
    lazygit

# ── System utilities ─────────────────────────────────────
pacman -S --needed \
    socat \
    python \
    gparted \
    xorg-xhost \
    gnome-keyring

# ── AUR packages ─────────────────────────────────────────
paru -S --needed \
    hyprland-per-window-layout \

dimarch::done "Hyprland stack installed"
