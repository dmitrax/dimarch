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
    match = { class = "^(dolphin|org.kde.dolphin)$" },
    float = true,
    persistent_size = true,
    size = { "monitor_w * 0.62", "monitor_h * 0.72" },
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
