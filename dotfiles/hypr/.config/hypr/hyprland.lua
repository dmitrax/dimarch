-- =========================================================
-- DimArch OS — Hyprland v0.55+ config
-- =========================================================

-- Base
require("modules/env")
require("modules/variables")

-- Monitors must be loaded early.
require("monitors")

-- Input / look / behavior
require("modules/input")
require("modules/general")
require("modules/colors")
require("modules/decoration")
require("modules/misc")
require("modules/xwayland")
require("modules/animations")

-- Rules
require("modules/rules")
require("modules/window-position-memory")

-- Workspace rules
-- Temporarily disabled while testing resume behavior.
require("modules/workspaces")

-- Binds / autostart
require("modules/keybinds")
require("modules/execs")
