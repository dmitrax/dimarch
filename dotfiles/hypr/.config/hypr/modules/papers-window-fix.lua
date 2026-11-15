-- =========================================================
-- DimArch OS — Papers maximize-on-open fix
--
-- Papers (org.gnome.Papers) requests its own maximized state on every
-- fresh window, which wins the race against rules.lua's static `size`
-- window_rule for the same class. The request is already in effect when
-- window.open fires, so the hook undoes it and then sizes the window.
--
--   1. hl.dsp.window.fullscreen takes an explicit setter:
--      { mode = "maximized" | "fullscreen", action = "set" | "unset" |
--      "toggle" }. `action = "unset"` takes a maximized window straight
--      back to normal in ONE dispatch (measured 2026-11-15: 1 -> 0 in
--      ~5ms, no pass through fullscreen=2). Found in Omarchy 4.5's
--      workspace-modes.lua. The earlier version of this hook only knew
--      the toggle form (no `action` key), which goes 1 -> 2 -> 0 and
--      needed two dispatches 250ms apart — a visible ~250ms flash of the
--      maximized window on every open.
--   2. hl.dsp.window.resize is REJECTED ("Window is fullscreen") while
--      the window is still fullscreen, so the unset has to land first.
--   3. Dispatching synchronously inside the window.open handler does
--      nothing at all (not even a failed attempt) — a timer defer is
--      required, even a very short one.
--   4. win.monitor.width/height are PHYSICAL pixels while win.monitor.x/y
--      are LOGICAL; win.monitor.mode.width/height (Hyprland 0.57) give the
--      logical size directly (2560x1440 on DP-1 at scale 1.5).
-- =========================================================

local CLASS = "org.gnome.Papers"
local FS_MODE = { [1] = "maximized", [2] = "fullscreen" }

local function find_window(address)
    for _, w in ipairs(hl.get_windows({ class = CLASS })) do
        if w.address == address then
            return w
        end
    end
    return nil
end

hl.on("window.open", function(win)
    if win.class ~= CLASS or not win.monitor then
        return
    end

    local logical_w = win.monitor.mode.width
    local logical_h = win.monitor.mode.height

    local w = math.floor(logical_w * 0.6)
    local h = math.floor(logical_h * 0.85)
    local x = win.monitor.x + math.floor((logical_w - w) / 2)
    local y = win.monitor.y + math.floor((logical_h - h) / 2)

    local target = "address:" .. win.address

    local function place()
        hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = target }))
        hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = target }))
    end

    hl.timer(function()
        local current = find_window(win.address)
        if not current then
            return
        end

        local mode = FS_MODE[current.fullscreen or 0]
        if not mode then
            place()
            return
        end

        hl.dispatch(hl.dsp.window.fullscreen({ mode = mode, action = "unset", window = target }))
        -- Let the unset land before resizing (see note 2).
        hl.timer(place, { timeout = 10, type = "oneshot" })
    end, { timeout = 10, type = "oneshot" })
end)
