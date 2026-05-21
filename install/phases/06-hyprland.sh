#!/bin/bash
source "$(dirname "$0")/../utils/helpers.sh"

dimarch::section "Hyprland Stack"

pacman -Sy --needed \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    uwsm \
    waybar \
    rofi-wayland \
    ghostty \
    dolphin kio kio-extras \
    ffmpegthumbs \
    kio-admin \
    ttf-jetbrains-mono-nerd \
    nerd-fonts-inter \
    grim \
    slurp \
    wl-clipboard \
    libnotify \
    satty \
    gnome-keyring \
    swayosd

dimarch::done "Hyprland stack installed"
