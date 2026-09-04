---
name: dimarch
description: >
  REQUIRED for customizing a DimArch OS machine — the Hyprland desktop, its bar,
  terminal, theme, idle and power behaviour. Use when editing anything under
  ~/.config/hypr/, ~/.config/waybar/, ~/.config/ghostty/, ~/.config/rofi/,
  ~/.config/swaync/, ~/.config/swayosd/, ~/.config/yazi/, ~/.config/dimarch/,
  or ~/.config/starship.toml. Triggers: keybinding, window rule, monitor,
  workspace, gaps, blur, opacity, waybar module, notification, theme, colour,
  wallpaper, idle timeout, lock screen, hibernate, screenshot, dimarchctl.
  Not for developing DimArch itself.
---

# DimArch OS

Customize a machine running [DimArch OS](https://github.com/dmitrax/dimarch) —
Arch Linux + CachyOS + Hyprland, floating-only, themed Sage.

This skill is for changing an installed system. It is not for developing DimArch;
that lives in the repository's own `CLAUDE.md`.

## When this skill must be used

- Editing any file under `~/.config/hypr/` — keybindings, monitors, window rules,
  animations, autostart
- Editing the bar (`~/.config/waybar/`), notifications (`~/.config/swaync/`),
  launcher (`~/.config/rofi/`), terminal (`~/.config/ghostty/`)
- Anything under `~/.config/dimarch/` — idle timeouts, sleep mode, VPN
- Any change to a colour, anywhere
- Running `dimarchctl`

**If you are about to edit a config file under `~/.config/` on this machine, read
this skill first.** Two rules below (colour, and repo-vs-live) exist because
ignoring them produced changes that looked applied and were not.

## Two directories, and they are not synchronized

```
~/.config/…                  the live system — this is what applications read
~/Projects/dimarch/dotfiles/ the repository — this is what a fresh install deploys
```

**Editing one does not change the other.** There is no sync, no symlink, no hook.
A repo edit reaches the live system only through `install/phases/06-dotfiles.sh`
or a manual copy — this has cost real debugging time twice, both times spent
wondering why a correct change did nothing.

So: **edit the live file under `~/.config/` first, confirm it works, then copy the
same content into the repository.** Never the other way round, and never only one
of the two. If the user asks for a permanent change, both are required — say so
if you only did one.

Reading the repository is useful and encouraged: it carries comments explaining
why a value is what it is.

## Colour is never chosen here

Not one hex is invented, copied from a neighbouring config, or eyeballed. Colours
come from the theme repository (`~/Projects/dimarch-theme`), through the `palette`
tool on `$PATH`:

```bash
palette component waybar          # which key of that config takes which role
palette role ramp.sage.base       # resolve one role to a value
palette where ramp.sage.base      # what breaks if that role changes
palette check ~/Projects/dimarch  # MANDATORY after any colour edit
```

`palette check` exiting non-zero means the config and the map disagree — fix it
before committing, never after.

If a key has no role, do not pick a similar-looking value: add the role to
`dimarch-theme` first, then use it. Three parallel sub-palettes once grew out of
exactly that shortcut.

**A colour you can see but cannot find in a config may be compiled into the
binary** (yazi's icons were), or may be an unset token falling through to a
terminal ANSI slot (Claude Code's own logo did, and rendered pink):

```bash
strings -a "$(command -v <app>)" | grep -oE '#[0-9a-f]{6}' | sort | uniq -c | sort -rn
```

See [`theming.md`](theming.md) before any theme work.

## Ask the system, do not recall it

Interfaces here have moved between versions, and a remembered syntax is how a
change silently does nothing:

```bash
dimarchctl commands --json        # every command, its args, whether it needs root
hyprctl repl 'inspect(hl.dsp)'    # the LIVE Hyprland Lua API — check before writing it
hyprctl binds                     # what a key is actually bound to right now
hyprctl configerrors              # after every Hyprland config change
cat "$(command -v dimarchctl)"    # reading the source is safe and often fastest
```

See [`hyprland.md`](hyprland.md) before touching the compositor config.

## Privileges

`sudo` does not work from an agent session: there is no controlling tty, and
sudo's ticket is bound to one, so `sudo -n` fails even when the same user's
`sudo -l -n` says otherwise.

`pkexec <command>` **does** work — polkit raises a graphical dialog and the user
types their password there. Rules:

- **Say what will happen before running it.** The dialog appears over whatever the
  user is doing; an unannounced password prompt is indistinguishable from malware.
- **Always wrap it in `timeout`.** If the user misses the dialog, the call hangs
  until they answer.
- **One `pkexec` per job.** There is no auth cache — a loop of them asks for the
  password every time. Put the whole root-side job in one script and elevate once.
- Ask before anything destructive: `pacman -Rns`, writes to `/boot` or the ESP,
  partition changes. One line, then act on the answer.

## Where things live

| What | Where | Applied by |
|---|---|---|
| Compositor | `~/.config/hypr/` (Lua) | auto-reload; verify `hyprctl configerrors` |
| Bar | `~/.config/waybar/config-top.jsonc`, `style.css` | `pkill waybar` then relaunch from `execs.lua` |
| Notifications | `~/.config/swaync/` | `swaync-client -rs` |
| Terminal | `~/.config/ghostty/config.ghostty` | new windows |
| Launcher | `~/.config/rofi/` | next invocation |
| Idle / lock / hibernate | `~/.config/dimarch/dimarch.conf` | `dimarchctl power apply` |
| Prompt | `~/.config/starship.toml` | next prompt |

`~/.config/hypr/hypridle.conf` is **generated** — edit `dimarch.conf` and run
`dimarchctl power apply`; a hand edit there is overwritten without warning.

## Decision framework

1. **Is there a `dimarchctl` command for it?** Use it — `dimarchctl commands`.
2. **Is it an idle/power/VPN setting?** Edit `~/.config/dimarch/dimarch.conf`,
   then `dimarchctl power apply`. Never edit the generated file.
3. **Is it a colour?** Follow [`theming.md`](theming.md). Resolve the role, never
   invent a value, and finish with `palette check`.
4. **Is it Hyprland?** Follow [`hyprland.md`](hyprland.md). Check the live API,
   then `hyprctl configerrors`.
5. **Is it another config?** Edit the live file, verify, then mirror it into the
   repository.
6. **Does it need root?** `pkexec`, announced, with a timeout.
7. **Unsure whether a command exists?** `dimarchctl commands --json`.

## Hardware constraints on this machine class

These are not preferences; each was found by breaking something:

- **RX 580 (Polaris):** `hyprctl dispatch dpms` and `wlopm --off/--on` kill GPU
  processes. `systemctl suspend` (S3) does not restore the GPU — windows vanish.
  Sleep means **hibernate**, and `monitor_off = none` is the only safe setting.
- **Fractional scaling + XWayland:** an upstream Hyprland bug misplaces cursor
  coordinates. Fix an affected app by giving it native Wayland, not by patching
  the compositor config.

Before changing anything under `[power]`, read the current state with
`dimarchctl power status`.

## Out of scope

Do not use this skill to develop DimArch itself: writing install phases, adding
package repositories, editing `install/`, or authoring migrations. That work has
its own rules in the repository.

## Example requests

| Request | Action |
|---|---|
| "Lock the screen after 10 minutes" | `lock_timeout = 600` in `~/.config/dimarch/dimarch.conf`, then `dimarchctl power apply` |
| "Bind Super+E to the file manager" | Check `hyprctl binds` first, unbind if taken, then edit `~/.config/hypr/modules/keybinds.lua` — see `hyprland.md` |
| "Make the bar accent brighter" | `palette component waybar`, pick the role, edit `style.css`, `palette check` |
| "Set up the second monitor" | `~/.config/hypr/monitors.lua`; positions are logical coordinates |
| "Is the VPN up?" | `dimarchctl vpn status` |
| "Why is the machine not sleeping?" | `dimarchctl power status`, then the hypridle service — do not edit `hypridle.conf` |
| "Install this package" | `pkexec pacman -S <pkg>`, announced first, with a timeout |

## Honest limits

This skill is new and deliberately narrow. It tells you where things live and
which shortcuts are known to break; it does not make a desktop change safe by
itself. Prefer plan mode for anything touching more than one file, and say plainly
when a change needs a relogin, a reboot, or a copy into the repository to survive
a reinstall.
