-- =========================================================
-- DimArch OS — Decoration
-- Hyprland v0.55+ / Lua config
-- Sage Theme — calm, clean, rooted. MATE-inspired floating desktop
-- =========================================================

hl.config({
    general = {
        -- Thin visible border helps floating windows feel separated,
        -- without making them look heavy.
        border_size = 1,

        col = {
            active_border = "rgba(00000024)",
            inactive_border = "rgba(00000010)",
        },
    },

    decoration = {
        -- macOS-like rounded corners
        rounding = 14,
        rounding_power = 2.8,

        -- Keep windows mostly opaque.
        -- Too much transparency makes floating desktops look flat and muddy.
        active_opacity = 1.0,
        inactive_opacity = 0.98,
        fullscreen_opacity = 1.0,

        -- Do not dim inactive windows globally.
        -- The shadow and subtle border are enough for depth.
        dim_inactive = false,

        blur = {
            enabled = true,

            -- Moderate blur: visible, but not "smeared".
            size = 8,
            passes = 2,

            -- Official docs recommend keeping this enabled for performance.
            new_optimizations = true,

            -- For a floating-only desktop, xray can make depth feel less natural.
            xray = false,

            -- Low noise keeps the blur clean.
            noise = 0.01,

            -- Neutral clean-light look.
            contrast = 1.0,
            brightness = 1.0,
            vibrancy = 0.12,
            vibrancy_darkness = 0.0,

            -- Keep menus/popups crisp.
            popups = false,
        },

        shadow = {
            enabled = true,

            -- Large soft shadow, closer to macOS-style depth.
            range = 34,

            -- 2 = softer falloff, 3 = slightly tighter.
            -- This is the best starting point for elegant floating windows.
            render_power = 2,

            sharp = false,

            -- Alpha controls strength.
            color = "rgba(00000038)",
            color_inactive = "rgba(00000020)",

            -- Slight downward shadow feels more natural.
            offset = { 0, 4 },

            scale = 0.98,
        },

        -- Hyprland 0.55 has glow, but for a classic macOS-like desktop
        -- it is better disabled. Glow often looks like a gamer halo.
        glow = {
            enabled = false,
        },
    },
})
