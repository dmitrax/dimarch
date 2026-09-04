# Theming: Sage

Read this before changing any colour.

DimArch's visual identity is **Sage**. This repository *consumes* colours; it does
not define them. The source of truth is `~/Projects/dimarch-theme`:

```
colors/palette.json      what colours exist and what each one means
colors/components.json   which key of which config takes which role
tools/palette            the only sanctioned way to read both
```

## The four commands

```bash
palette component ghostty            # every key of that config and its role
palette role role.git.branch         # resolve one role to a value
palette where ramp.sage.base         # everything that breaks if this changes
palette check ~/Projects/dimarch     # MANDATORY after any colour edit
```

`palette check` compares every mapped key against the file on disk. Non-zero exit
means they disagree — that is a blocker, not a warning.

## The rules, and why each exists

1. **Never invent a hex, never copy one from a neighbouring config.** By July 2026
   that shortcut had produced three parallel sub-palettes that all called
   themselves Sage.
2. **No role for what you need? Add the role to `dimarch-theme` first**, then
   reference it. A value with no role is a value nothing can verify.
3. **Component missing from the map? Add it to the map first**, then edit its
   config.
4. **Verify by resolving every value, not by reading the diff.** A diff confirms
   what changed and says nothing about what you failed to change.

## An unset key is not a neutral default

The trap that catches every theme sooner or later: **an application upgrade can
take a colour away in silence.** A new version splits new tokens out of surfaces
the config already painted; the new tokens fall back to the base theme, nothing is
logged, and any validator answers "ok" — because a key you did not set is a
default, not an error. Only the token count moves.

Two live examples on this system:

- **herdr 0.8.2** split off `sidebar_bg`, `active_row_bg` and `selection_bg`,
  which landed on catppuccin's cold violet.
- **Claude Code** bases its theme on `dark-ansi`, where every unset token resolves
  to a *terminal ANSI slot*. Its own brand tokens map to `ansi:redBright`, which
  Ghostty here defines as `clay.bright` — so the logo rendered pink until the
  brand colours were set explicitly.

After upgrading any themed application, re-read its token list from the binary
rather than assuming an untouched config means an untouched appearance:

```bash
strings -a "$(readlink -f "$(command -v <app>)")" | grep -oE '#[0-9a-f]{6}' | sort | uniq -c
```

Rust binaries pack struct field names into blocks **by length**, so one grep for
`StructName[a-z_]*` returns a partial list — short names live elsewhere. Collect
across blocks or undercount.

## Transparency: a terminal cell is transparent only while nobody names its background

Ghostty runs at `background-opacity = 0.85` with Hyprland's blur behind it. Any TUI
that sets a background explicitly makes that cell **opaque**, and it drops out of
the blur — inside a translucent window this reads as a foreign slab. There is no
in-between: picking a hex closer to the background does not help, it is the same
slab with a visible edge.

So for a panel inside a TUI the question is not "which shade" but "fill or glass".
Where glass is wanted, leave the key unset (or set it to the app's own reset
value) rather than painting it near-background.

## Decide what paints what by sampling, not by reading

Whether an application paints a surface itself is settled by sampling the rendered
window, never by reading its config or a comment in it:

```bash
hyprctl clients -j          # geometry of the window
grim -g "<geometry>" out.png
```

Then look at the colour distribution over the region: one repeated colour means a
solid fill; a spread means transparency (wallpaper through opacity and blur). A
comment in a config claiming a key paints a sidebar survived a month and a half
here before a sample disproved it.

## Flattened values

A TUI can only be handed an opaque hex, so a colour meant to be a translucent
overlay is **flattened** over the surface behind it and stored as the result. Those
values carry a note in `palette.json` saying what they were flattened over — if
that background changes, they must be recomputed. Do not treat them as free
constants.
