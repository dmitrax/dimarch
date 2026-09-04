# Hyprland on DimArch

Read this before changing keybindings, monitors, window rules, animations or
autostart.

DimArch configures Hyprland in **Lua**, not in `hyprland.conf`:

```
~/.config/hypr/
├── hyprland.lua            entry point, requires the modules below
├── monitors.lua            display layout (hardware-specific, kept out of modules/)
└── modules/
    ├── env.lua             environment variables — the single source of truth
    ├── decoration.lua      blur, shadow, animations
    ├── rules.lua           window rules; everything floats, always
    ├── keybinds.lua        keybindings
    ├── input.lua           keyboard layouts (us,ru,ua)
    └── execs.lua           autostart on hyprland.start
```

## Check the API before writing it

The Lua API has changed between Hyprland releases and does not match what a model
remembers. `hyprctl repl` reports the live truth:

```bash
hyprctl repl 'hl.version()'
hyprctl repl 'inspect(hl.dsp.window)'      # what dispatchers actually exist
hyprctl repl 'inspect(hl.dsp)'
```

Two that cost real time here: `hl.dsp.window.focus` does not exist (it is
`hl.dsp.focus({ window = 'address:…' })`), and `hyprctl dispatch` in Lua mode does
**not** accept the classic dispatcher names such as `movetoworkspacesilent`.

After every change:

```bash
hyprctl reload && hyprctl configerrors
```

`configerrors` printing nothing is the pass. Hyprland auto-reloads on save, but a
silent config error just leaves the old value in place.

## Rebinding a key

Always, in this order:

1. `hyprctl binds` — find out what the key does today.
2. If it is taken, unbind it before binding it again.
3. **Tell the user what the key used to do.** A silently stolen binding is
   discovered days later.
4. `hyprctl reload`, then `hyprctl binds` again — confirm the new bind actually
   registered. It does not always: a modifier used as the trigger key alongside a
   different required modifier (`SUPER + Control_R`) registers nothing, reports no
   error, and simply never appears. A bare modifier on its own (`Super_L`) works.

Submaps must be declared with `hl.define_submap("name", function() … end)`;
binding into a submap that was never declared fails only when you switch to it.

## Windows

DimArch is floating-only. `rules.lua` carries a global catch-all with
`persistent_size = true`, which makes Hyprland reapply the last size of a window
class to the next window of that class. For any app that computes its own size per
open (image viewers, PDF readers), add `persistent_size = false` to that app's own
more specific rule — otherwise the app's fresh calculation loses a race against
the remembered value.

Window rule *syntax* has changed repeatedly upstream. Check the current wiki
(https://wiki.hypr.land/Configuring/Basics/Window-Rules/) rather than trusting a
remembered form.

Two more that look like bugs in your code and are not:

- Dispatching **synchronously inside a `window.open` handler does nothing at all**
  — not an error, a silent no-op. Wrap it in `hl.timer(fn, {timeout = 10, type =
  "oneshot"})`. The type is `"oneshot"` or `"repeat"`; `"once"` is not a value.
- Geometry dispatched on `window.open_early` **crashes the compositor** — the
  toplevel has no buffer yet. Use `window.open`.

## Monitors

`monitors.lua` holds the layout. Positions are logical coordinates.

```bash
hyprctl monitors all       # names, modes, current scale
```

A trap when computing geometry by hand inside a Lua hook: on `HL.Monitor`,
`width`/`height` are **physical pixels** while `x`/`y` are **logical layout
coordinates**. Divide by `scale` before using width/height, or the numbers
overshoot the monitor and Hyprland clamps the window back. The Vec2 expression
syntax inside `hl.window_rule` (`"monitor_w * 0.6"`) already resolves logically —
this only bites hand-rolled arithmetic.

## Environment variables

`env.lua` returns its table, and `execs.lua` passes those names to
`uwsm finalize` on `hyprland.start`. That call is what exports them to the systemd
user manager — without it, XDG autostart apps (which UWSM runs as their own units)
see none of them, no matter what `hl.config({ env = … })` says. Adding a variable
to `env.lua` is enough; do not hand-copy it into a `.desktop` file.

The effect needs a fresh compositor start, since the hook fires once.

## Debugging when nothing is logged

`journalctl _PID=<hyprland-pid>` shows Hyprland's own stdout including Lua
`print()`. If the journal goes quiet, log to a file from Lua directly
(`io.open("/tmp/x.log","a")`). Note `os.clock()` here returns CPU time, not
wall-clock — useless for measuring how long something took.
