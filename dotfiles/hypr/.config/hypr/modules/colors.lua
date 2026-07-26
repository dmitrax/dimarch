-- =========================================================
-- DimArch OS — Colors
-- Sage Theme — static colors until matugen is configured
-- =========================================================
-- Single source for Hyprland's own palette. modules/decoration.lua owns
-- border GEOMETRY (size, rounding, shadow shape) and deliberately sets no
-- colors, so this file is the only place window-chrome color is decided.
--
-- 2026-07-26: these two keys used to be declared in BOTH files. hyprland.lua
-- requires colors before decoration, so decoration silently won and the
-- values here (#7c8cd8 / #c8cad4 — a blue-violet pair left over from a
-- pre-Sage config) were dead code. Reordering the two require lines would
-- have turned every window border violet under a file titled "Sage Theme".
-- The values below are the ones that were actually rendering.
--
-- Borders are intentionally near-transparent black rather than a sage tint:
-- Hyprland draws them around every window on top of arbitrary content, so a
-- neutral shadow-like edge separates windows without tinting them. Sage lives
-- on the panel and in-app chrome, not on the window frame.

hl.config({
    general = {
        col = {
            active_border   = "rgba(00000024)",
            inactive_border = "rgba(00000010)",
        },
    },
})
