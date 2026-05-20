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
