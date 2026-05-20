-- DP-2 = Dell FullHD — left
-- DP-1 = LG 4K       — right, scale 1.5 → effective 2560x1440
hl.monitor({
    output     = "DP-2",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output     = "DP-1",
    mode     = "3840x2160@60",
    position = "1920x0",
    scale    = 1.5,
})
