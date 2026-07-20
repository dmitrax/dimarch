-- =============================================================
-- DimArch OS — workspaces.lua
-- Persistent workspace topology.
--
-- DP-1 = LG 4K      — RIGHT (main)  — workspaces 1-5
-- DP-2 = Dell FullHD — LEFT          — workspaces 6-7
--
-- persistent = true  → workspace survives monitor disconnect
--                       (suspend/resume, wlopm off/on)
-- default = true     → which workspace the monitor shows on
--                       first connect / after resume
-- =============================================================

-- Main monitor: LG 4K / DP-1
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true })

-- Secondary monitor: Dell FullHD / DP-2
hl.workspace_rule({ workspace = "6", monitor = "DP-2", default = true, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-2", persistent = true })
