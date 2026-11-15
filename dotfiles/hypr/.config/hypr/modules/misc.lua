hl.config({
    misc = {
        disable_hyprland_logo    = true,
        force_default_wallpaper  = 0,
        disable_splash_rendering = true,
        allow_session_lock_restore = true,
        animate_manual_resizes   = false,
        -- Floating-only desktop: a window dragged entirely off its monitor
        -- is brought back half-visible (1). Not 2: that pins a window fully
        -- inside the monitor it is assigned to, which yanks windows placed
        -- across the DP-2/DP-1 seam back onto their own monitor.
        float_force_onscreen     = 1,
    },
})

-- Never switch a monitor into HDR on its own. Hyprland's default
-- (cm_auto_hdr = 1) flips the output to HDR whenever a fullscreen app
-- presents HDR content — e.g. an HDR video going fullscreen — and HDR
-- output looks wrong on this setup. 0 keeps every output in SDR; the
-- app's HDR content is tone-mapped instead.
hl.config({
    render = {
        cm_auto_hdr = 0,
    },
})

-- Blur for Waybar panels
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.3 })

-- Blur for rofi
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0.3 })

-- Shadow for rofi
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })
