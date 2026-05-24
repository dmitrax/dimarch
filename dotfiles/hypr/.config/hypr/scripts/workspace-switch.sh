#!/bin/bash
# Switch workspace — Hyprland 0.55 Lua dispatch compatible
hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$1' }))"
