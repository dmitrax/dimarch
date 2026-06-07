-- =========================================================
-- DimArch OS — Hyprland v0.55+ config
-- =========================================================

-- Base
require("hyprland/env")
require("hyprland/variables")

-- Monitors must be loaded early.
require("monitors")

-- Input / look / behavior
require("hyprland/input")
require("hyprland/general")
require("hyprland/colors")
require("hyprland/decoration")
require("hyprland/misc")
require("hyprland/xwayland")
require("hyprland/animations")

-- Rules
require("hyprland/rules")

-- Workspace rules
-- Temporarily disabled while testing resume behavior.
require("hyprland/workspaces")

-- Binds / autostart
require("hyprland/keybinds")
require("hyprland/execs")
