-- =========================================================
-- DimArch OS — swayimg (image viewer)
-- Sage palette. No client-drawn window chrome: Hyprland handles
-- frame/border/rounding (same convention as ghostty's
-- window-decoration=none).
-- =========================================================

-- Sage palette (ARGB hex), from the TERMINAL surface family — ghostty's
-- background + #edeae4 text, shared with yazi/starship/uosc. An earlier
-- comment here claimed these came from waybar/style.css and "matches mako";
-- neither held. Waybar is a translucent glass surface on a different base
-- (13,23,25) with #c4ddd2 text, and mako was replaced by swaync. swayimg
-- draws opaque panels over arbitrary images, so the opaque terminal family
-- is the correct parent. Corrected + resynced 2026-07-26 (was #16161c,
-- ghostty moved to #171a1b).
local bg        = 0xff171a1b -- terminal bg (solid)
local bg_card   = 0xff1d2021 -- subtle lift over bg, same +6 step as before
local bg_panel  = 0xcc171a1b -- translucent text-overlay backdrop
local text_main = 0xffedeae4
local accent    = 0xff7fb89e
local accent_bg = 0x337fb89e -- accent @ ~20% alpha, matches Waybar's bg_active

-- General
swayimg.enable_antialiasing(true)
swayimg.enable_decoration(false) -- Hyprland draws borders/rounding, not the app
swayimg.enable_exif_orientation(true)
swayimg.set_dnd_button("MouseRight")

-- Image list — arrow through neighboring files when opened on a single image
swayimg.imagelist.enable_adjacent(true)
swayimg.imagelist.set_order("alpha")

-- Text overlay
swayimg.text.set_font("Inter Variable")
swayimg.text.set_size(13)
swayimg.text.set_padding(14)
swayimg.text.set_spacing(2)
swayimg.text.set_foreground(text_main)
swayimg.text.set_background(bg_panel)
swayimg.text.set_shadow(0x00000000) -- flat, background chip instead of a drop shadow
swayimg.text.set_timeout(5)
swayimg.text.set_status_timeout(3)

-- Auto-size the window to the image, macOS-Preview style, instead of a fixed
-- default size. Clamped to the smaller of the two monitors (Dell FullHD,
-- 1920x1080 logical) minus room for gaps/panel, so a large photo never
-- overflows regardless of which monitor picks up the window.
--
-- Only resizes once, on the first image of the session. Resizing again on
-- every Up/Down page produces a visible blur/cross-fade between frames.
-- Confirmed this is a separate issue from the "image doesn't re-fit after
-- resize" bug fixed below (retested per-page resize with that fix in place —
-- artifact came right back), and ruled out Hyprland's window animation and
-- blur (persists with animations:enabled=false and with no_blur on the
-- window). Also tried opaque+force_rgbx on the window rule (rules.lua) —
-- made it worse: window stopped resizing past the first image, and stale
-- content from earlier images stayed visible underneath the new one. Not
-- investigated further — a one-time resize already satisfies the actual
-- goal (no tiny default window) without the artifact while paging.
local MAX_W = 1700
local MAX_H = 950
local function fit_to_max(w, h)
    local scale = math.min(1, MAX_W / w, MAX_H / h)
    return math.floor(w * scale), math.floor(h * scale)
end
-- Re-fit once the resize actually lands (set_window_size is a request, not
-- synchronous — calling set_fix_scale right after set_window_size still sees
-- the OLD size, since the resize hasn't been applied yet at that point in the
-- same callback. on_window_resize fires when it genuinely has.)
swayimg.on_window_resize(function()
    swayimg.viewer.set_fix_scale("fit")
end)

local resized_once = false
swayimg.viewer.on_image_change(function()
    if resized_once then return end
    resized_once = true
    local image = swayimg.viewer.get_image()
    if image then
        swayimg.set_window_size(fit_to_max(image.width, image.height))
    end
end)

-- Viewer mode
swayimg.viewer.set_default_scale("fit") -- window is already sized to the image
swayimg.viewer.set_default_position("center")
swayimg.viewer.set_drag_button("MouseLeft")
swayimg.viewer.set_window_background(bg)
swayimg.viewer.set_image_chessboard(16, bg_card, bg) -- subtle dark checker, not the default black/white
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.set_mark_color(accent)
swayimg.viewer.set_text("topleft", { "{name}" })
swayimg.viewer.set_text("topright", { "{list.index} / {list.total}" })
swayimg.viewer.set_text("bottomleft", { "{frame.width}x{frame.height} · {scale}" })

-- Slide show mode — same brand background, no default blur/mirror
swayimg.slideshow.set_default_scale("fit")
swayimg.slideshow.set_window_background(bg)
swayimg.slideshow.set_text("topleft", { "{name}" })

-- Gallery mode (directory browsing)
swayimg.gallery.set_aspect("fill")
swayimg.gallery.set_thumb_size(180)
swayimg.gallery.set_padding_size(8)
swayimg.gallery.set_border_size(3)
swayimg.gallery.set_border_color(accent)       -- selection border in Sage green
swayimg.gallery.set_selected_scale(1.08)
swayimg.gallery.set_selected_color(accent_bg)  -- same tint as Waybar's active-module highlight
swayimg.gallery.set_unselected_color(bg_card)
swayimg.gallery.set_window_color(bg)
swayimg.gallery.enable_hover(true)
swayimg.gallery.enable_embedded_thumb(true)
swayimg.gallery.set_mark_color(accent)
swayimg.gallery.set_text("topleft", { "{name}" })
swayimg.gallery.set_text("topright", { "{list.index} / {list.total}" })

-- Escape closes the viewer/gallery, matching the rest of the desktop's exit conventions
swayimg.viewer.on_key("Escape", function() swayimg.exit() end)
swayimg.slideshow.on_key("Escape", function() swayimg.exit() end)
swayimg.gallery.on_key("Escape", function() swayimg.exit() end)

-- Up/Down browse the folder (default binds them to panning instead — Left/Right
-- and mouse-drag still pan). Plain scroll wheel zooms (default only zooms on
-- Ctrl-scroll, plain scroll pans by default).
swayimg.viewer.on_key("Up", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("Down", function() swayimg.viewer.switch_image("next") end)

local function zoom_at_mouse(step)
    return function()
        local pos = swayimg.get_mouse_pos()
        local scale = swayimg.viewer.get_scale()
        swayimg.viewer.set_abs_scale(scale + scale * step, pos.x, pos.y)
    end
end
swayimg.viewer.on_mouse("ScrollUp", zoom_at_mouse(0.1))
swayimg.viewer.on_mouse("ScrollDown", zoom_at_mouse(-0.1))
