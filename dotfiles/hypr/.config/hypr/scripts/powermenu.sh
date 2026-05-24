#!/bin/bash
chosen=$(printf "  Shutdown\n  Reboot\n  Sleep\n  Lock" | \
    rofi -dmenu -p "Power" -i)

case "$chosen" in
    "  Shutdown") systemctl poweroff ;;
    "  Reboot")   systemctl reboot ;;
    "  Sleep")    systemctl suspend ;;
    "  Lock")     loginctl lock-session ;;
esac
