-- =========================================================
-- DimArch OS — Window Rules
-- Hyprland v0.55+ / Lua config
-- Floating-only desktop behavior
-- =========================================================

-- ---------------------------------------------------------
-- Global floating behavior
-- ---------------------------------------------------------

-- Classic desktop base:
-- all windows are floating.
--
-- persistent_size works only inside the current Hyprland session.
-- After reboot, app-specific size rules below provide sane defaults.
hl.window_rule({
    match = { class = ".*" },
    float = true,
    persistent_size = true,
})

-- ---------------------------------------------------------
-- Utility / launcher windows
-- ---------------------------------------------------------

hl.window_rule({
    match = { class = "^(rofi)$" },
    float = true,
    center = true,
    no_blur = true,
    no_shadow = true,
    decorate = false,
})

-- ---------------------------------------------------------
-- Browsers
-- ---------------------------------------------------------

-- Firefox: sane default after reboot,
-- then persistent_size remembers manual resizing during the session.
hl.window_rule({
    match = { class = "^(firefox)$" },
    float = true,
    persistent_size = true,
    size = { "monitor_w * 0.82", "monitor_h * 0.86" },
    center = true,
})

-- LibreWolf class can be librewolf or LibreWolf depending on package/build.
hl.window_rule({
    match = { class = "^(librewolf|LibreWolf)$" },
    float = true,
    persistent_size = true,
    size = { "monitor_w * 0.82", "monitor_h * 0.86" },
    center = true,
})

-- ---------------------------------------------------------
-- File manager
-- ---------------------------------------------------------

hl.window_rule({
    match = { class = "^(thunar)$" },
    float = true,
    persistent_size = true,
    center = true,
})

-- ---------------------------------------------------------
-- Terminal
-- ---------------------------------------------------------

-- Ghostty defines its own initial size through:
-- ~/.config/ghostty/config.ghostty
--
-- Do not force size here, otherwise Hyprland overrides
-- Ghostty's window-width/window-height.
hl.window_rule({
    match = { class = "^(foot|com.mitchellh.ghostty|ghostty)$" },
    float = true,
    persistent_size = true,
    center = true,
})

-- ---------------------------------------------------------
-- Dialogs / small utility windows
-- ---------------------------------------------------------

hl.window_rule({
    match = {
        title = "^(Open File|Save File|Choose File|Preferences|Settings|Properties)$",
    },
    float = true,
    center = true,
    persistent_size = true,
})

-- ---------------------------------------------------------
-- Image viewer
-- ---------------------------------------------------------

-- swayimg auto-sizes its window once on open (see
-- dotfiles/swayimg/.config/swayimg/init.lua). Resizing on every page instead
-- caused a blur/transparency artifact confirmed independent of both
-- Hyprland's animations and blur (no_anim/no_blur tested, artifact persisted
-- either way) — root cause not pursued further, see init.lua for the
-- one-time-resize workaround this rule no longer needs to work around.
--
-- persistent_size = false overrides the global catch-all rule above: without
-- this, Hyprland remembers the last swayimg window's size for the session and
-- races it against our own on_image_change resize, so opening a new image
-- unpredictably keeps the previous image's (wrong aspect) size instead of
-- fitting the new one. Same fix already used for Satty below, same reason.
-- Tried opaque + force_rgbx as a candidate fix (theory: the "transparency"
-- version of the artifact came from Hyprland compositing an undefined-alpha
-- region during the transitional resize frame) — made things worse instead:
-- the window stopped resizing at all past the first image, and stale content
-- from earlier images stayed visible underneath the new one (a redraw/damage
-- bug, not just an alpha one). Reverted; not worth pursuing further.
hl.window_rule({
    match = { class = "^(swayimg)$" },
    center = true,
    persistent_size = false,
})

-- ---------------------------------------------------------
-- Video player (mpv)
-- ---------------------------------------------------------

-- mpv sizes its own window per-video via autofit-larger in mpv.conf, but the
-- global catch-all rule above (persistent_size = true) remembers the last
-- mpv window's size for the session and re-applies it to every new video
-- regardless of resolution — same bug already found and fixed for swayimg
-- and Satty below, same fix: override persistent_size = false here so each
-- video actually gets mpv's own computed size instead of the previous one.
hl.window_rule({
    match = { class = "^(mpv)$" },
    center = true,
    persistent_size = false,
})

-- ---------------------------------------------------------
-- Picture-in-Picture
-- ---------------------------------------------------------

hl.window_rule({
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { 480, 270 },
    move = { "monitor_w-window_w-24", "monitor_h-window_h-64" },
})

-- Satty screenshot annotation window
hl.window_rule({
    match = { class = "^(com.gabm.satty)$" },
    float = true,
    persistent_size = false,   -- override global rule
    center = true,
})

-- ---------------------------------------------------------
-- XWayland apps
-- ---------------------------------------------------------
 
-- XWayland windows default to position 0,0 (top-left corner).
-- This rule centers all XWayland windows on open.
hl.window_rule({
    match = { xwayland = true },
    center = true,
})

-- force_zero_scaling (xwayland.lua) has a longstanding upstream cursor/coordinate
-- bug on fractional-scale outputs (Hyprland issues #2880, #4521, #2566, #7769,
-- #5144, #9642 — still open as of 2026-07): submenus collapse, misclicks, artifacts.
-- Zoom escaped this class of bug entirely by switching to native Wayland
-- (xwayland=false in ~/.config/zoomus.conf) — no longer pinned here.
--
-- Enpass has no native Wayland build (xcb-only Qt backend), so it used to hit
-- this bug and was pinned to DP-2 (integer scale 1.0) to avoid the coordinate
-- math issue. Unpinned 2026-07-09 after installing qt5ct/qt6ct (env.lua's
-- QT_QPA_PLATFORMTHEME=qt6ct now actually resolves) — submenus stopped
-- collapsing on mouse movement. Root cause not confirmed (the upstream
-- Hyprland/XWayland bug above is still open) — could be qt6ct fixing Qt's own
-- DPI/scaling fallback rather than the coordinate bug itself. If submenus
-- start collapsing again on the LG (DP-1, fractional scale), re-add:
--   hl.window_rule({ match = { class = "^(Enpass|enpass)$" }, monitor = "DP-2" })
--
-- Lock the main window to its current comfortable size instead of whatever
-- Enpass defaults to on fresh launch.
hl.window_rule({
    match = { class = "^(Enpass|enpass)$", title = "^Enpass$" },
    size = { 1166, 782 },
})

-- Enpass Assistant is the small autofill/quick-access helper popup (shares
-- the same window class as the main app, distinguished by title). Overriding
-- center=true (from the xwayland catch-all above) back off let the app's own
-- requested position through, but that position turned out to be wherever
-- Enpass's own X11 popup logic lands (tested 2026-07-09: landed off-center,
-- not near the Waybar tray or a browser icon) — Hyprland has no way to know
-- where the tray/extension icon actually is, so there's nothing to anchor to.
-- Pinned to a fixed spot near the DP-1 Waybar tray instead, for a predictable
-- location rather than a wrong-but-varying one. `move` here is relative to the
-- target monitor's own origin (confirmed empirically 2026-07-09: with
-- monitor="DP-1" set, move={4144,40} landed at global (6064,40) = 1920 [DP-1's
-- global x offset] + 4144 — the first attempt wrongly used a global-space
-- value). DP-1 logical size is 2560x1440 (3840x2160 @ 1.5 scale) — 2224 puts
-- the window's left edge near the right end of the bar, under the tray.
hl.window_rule({
    match = { class = "^(Enpass|enpass)$", title = "^Enpass Assistant$" },
    monitor = "DP-1",
    move = { 2224, 40 },
})
