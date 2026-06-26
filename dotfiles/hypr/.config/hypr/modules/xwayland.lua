-- =========================================================
-- DimArch OS — XWayland configuration
-- Hyprland v0.55+ / Lua config
-- =========================================================

-- force_zero_scaling: renders XWayland windows at scale 1,
-- preventing blurry/pixelated fonts on HiDPI monitors.
-- Each app then controls its own scaling (Steam, Enpass, etc.)
--
-- use_nearest_neighbor: disabled — bilinear looks better
-- when XWayland windows are scaled up by the compositor.
hl.config({
    xwayland = {
        force_zero_scaling = true,
        use_nearest_neighbor = false,
    },
})
