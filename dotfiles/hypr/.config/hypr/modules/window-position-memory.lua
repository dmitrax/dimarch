-- =========================================================
-- DimArch OS — Window position memory for tray apps
--
-- Wayland gives clients no way to request their own screen position
-- (unlike X11) — placement is always the compositor's call. Apps that
-- minimize to tray (Telegram, etc.) destroy their toplevel on hide and
-- get a brand new one on restore, so Hyprland places it fresh each
-- time (default: centered) instead of remembering anything.
--
-- Mechanism:
--   1. A repeating timer polls tracked windows' geometry while they're
--      mapped (no per-drag event exists to hook instead). Frames with
--      zero/negative size (e.g. mid-animation while hiding to tray) are
--      dropped so a bad snapshot never gets saved.
--   2. On "window.open" — fired once the new toplevel is fully mapped,
--      as opposed to "window.open_early" which fires before its first
--      frame, while it has no output/buffer assigned yet — the saved
--      geometry is re-applied via hl.dispatch. Applying geometry at
--      open_early crashed Hyprland (libpixman "Invalid rectangle
--      passed" in pixman_region32_union_rect) because the resize/move
--      landed on a window with no valid surface to compute damage
--      against yet.
--
-- In-memory only: state resets on Hyprland restart/reload, same scope
-- as the global persistent_size rule in rules.lua.
-- =========================================================

-- Add more classes here if other tray apps show the same behavior.
local TRACKED_CLASSES = {
    "TelegramDesktop",
    "org.telegram.desktop",
}

local last_known = {}

hl.timer(function()
    for _, class in ipairs(TRACKED_CLASSES) do
        local wins = hl.get_windows({ class = class })
        for _, w in ipairs(wins) do
            if w.floating and w.at and w.size and w.size.x > 0 and w.size.y > 0 then
                last_known[class] = {
                    x = w.at.x, y = w.at.y,
                    w = w.size.x, h = w.size.y,
                }
            end
        end
    end
end, { timeout = 2000, type = "repeat" })

hl.on("window.open", function(win)
    local saved = last_known[win.class]
    if not saved or saved.w <= 0 or saved.h <= 0 then
        return
    end

    hl.dispatch(hl.dsp.window.resize({ x = saved.w, y = saved.h, window = "address:" .. win.address }))
    hl.dispatch(hl.dsp.window.move({ x = saved.x, y = saved.y, window = "address:" .. win.address }))
end)
