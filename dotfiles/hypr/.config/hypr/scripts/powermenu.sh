#!/bin/bash
chosen=$(printf "󰐥  Shutdown\n  Reboot\n  Sleep\n  Lock\n  Logout" | \
    rofi -dmenu -p "Power" -i)

case "$chosen" in
    "󰐥  Shutdown") systemctl poweroff ;;
    "  Reboot")   systemctl reboot ;;
    "  Sleep")    dimarch-sleep ;;
    "  Lock")     loginctl lock-session ;;
    "  Logout")   uwsm stop ;;
esac
