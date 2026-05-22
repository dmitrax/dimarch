local mod = "SUPER"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + Space",  hl.dsp.exec_cmd("rofi -show drun"))

-- Window management
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + F",      hl.dsp.window.fullscreen({ fullscreen = true }))
hl.bind(mod .. " + L",      hl.dsp.exec_cmd("hyprlock"))

-- Move & resize with mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for i = 1, 4 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Reload config
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("hyprctl reload"))

-- =========================================================
-- Screenshots
-- grim + slurp + wl-copy + satty
-- =========================================================

-- Print
-- Select area, save PNG to ~/Pictures/Screenshots and copy to clipboard.
hl.bind("Print", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh area"
))

-- Super + Shift + S
-- Select area, save PNG and copy to clipboard.
-- Familiar macOS/Windows-style shortcut.
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh area"
))

-- Super + Shift + E
-- Select area and open it in Satty for annotation.
-- Does NOT auto-save. In Satty:
-- Enter / Ctrl+C = copy result to clipboard
-- Ctrl+S         = save manually, if needed
-- Esc            = exit
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh area-edit"
))

-- Super + Print
-- Full screen, save PNG and copy to clipboard.
hl.bind("SUPER + Print", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh screen"
))

-- Super + Shift + Print
-- Full screen and open it in Satty for annotation.
-- Does NOT auto-save.
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh screen-edit"
))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })

-- =========================================================
-- Lock screen
-- =========================================================

-- Trigger a system lock event.
-- hypridle receives it and runs lock_cmd:
-- switch layout to EN, then start hyprlock.
hl.bind("SUPER + L", hl.dsp.exec_cmd(
    "loginctl lock-session"
))
