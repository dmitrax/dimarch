# DimArch OS — Branding Decisions

> This document is authoritative. Feed it to Claude Code before any
> naming, README, or documentation task.

---

## Core Brand

### Name

**DimArch OS**

Public interpretation: **Dimmed Arch** — not named after a person.
A quieter, more deliberate Arch Linux desktop.

Do not explain the name as "Dima + Arch" in any public-facing material.

### Primary tagline

> Modern system. Old soul.

Use everywhere: README, SDDM screen, About dialog, social media bio.

### Secondary phrase

> Dimmed, not dumbed down.

Use in: philosophy section, README About, blog posts, landing page.
Function: pre-empts the misreading of "dimmed" as "simplified" or "weak".
The system is calmer and quieter — not lesser.

### One-paragraph description

DimArch OS is an opinionated Arch Linux desktop system: calm by design,
fast by default, and structured as a complete daily system rather than
a pile of dotfiles. DimArch means Dimmed Arch — a quieter, more deliberate
desktop built on Hyprland, BTRFS, GRUB, and the Sage visual identity.

---

## Visual Identity — Sage

**Sage** is the design language of DimArch OS.

Not a DE. Not a shell. A visual identity: colors, typography, spacing,
motion, and the aesthetic tone of every component.

### Correct usage

- "DimArch OS uses the Sage visual identity."
- "Styled with Sage."
- "dimarch-theme contains the Sage design system."

### Incorrect usage (avoid)

- "Sage Desktop" — Sage is not a DE.
- "Sage DE" — same.
- Naming any shell component "Sage ___".

### Sage palette

**This table is a summary, not the source.** Colour values live in
[dimarch-theme](https://github.com/dmitrax/dimarch-theme) — `colors/palette.json`
is the source of truth and `colors/sage-dark.css` mirrors it as CSS tokens.
Anything below that disagrees with those files is stale; fix it there, not here.

| Token     | Hex       | Palette path         | Usage                              |
|-----------|-----------|----------------------|------------------------------------|
| brand     | `#7fb89e` | `ramp.sage.base`     | the accent — highlights, focus      |
| text      | `#c4ddd2` | `ramp.sage.bright`   | primary text on chrome and terminal |
| panel-bg  | `#0d1919` | `surface.chrome.panel` | panel / bar background, 78% alpha |
| terminal  | `#171b1b` | `surface.terminal.bg` | opaque terminal ground             |
| text-muted| `#82828c` | `neutral.muted`      | comments, inactive                  |
| border    | `#324040` | `surface.terminal.border` | separators and table rules     |

Five hue families sit on a warm arc 0°–176°: cinnamon 19° (media), ochre 36°
(change, archives), lichen 88° (executables), sage 153° (the brand), patina 176°
(links, documents). Clay 0° sits outside the arc on purpose — red for failure is a
convention, and a signal that blends into the harmony stops reading as a signal.

The previous version of this table listed `#16161c`, `#f0ede4`, `#2a2a35`,
`#6b6b7a` and `#3a3a4a` — a fourth parallel palette that appeared in no component
and had drifted from the real theme entirely. Replaced 2026-07-27.

### Sage tagline

> Calm. Clean. Rooted.

---

## Component Naming — dimarch-* pattern

All project components follow `dimarch-*` naming consistently.

| Component               | Repo / path                    | Status      |
|-------------------------|--------------------------------|-------------|
| dimarch                 | `dmitrax/dimarch`              | active      |
| dimarch-theme           | `dmitrax/dimarch-theme`        | active      |
| dimarch-taskbar         | `dmitrax/dimarch-taskbar`      | in dev      |
| dimarch-daycenter       | future repo                    | planned     |
| dimarch-desktop-layer   | future component               | planned     |
| dimarch-control-center  | future component               | planned     |
| dimarchctl              | `dimarch/install/utils/`       | planned     |
| dimarch-health-check    | `dimarch/install/utils/`       | planned     |

**Rule:** Do not introduce sub-brands or alternative naming patterns
for individual components. Consistency beats creativity here.

---

## Reserved Codename — Aloe

**Aloe** is reserved as a possible future name for a standalone
desktop environment, if and when DimArch components mature to the
point where they can be installed independently of DimArch OS
on any Arch/Hyprland system.

Until that point: **Aloe is not a public brand layer.**

Aloe may be used internally as:
- A codename reference in roadmap notes
- A philosophical shorthand ("Aloe Vera for Linux desktop burns")
- A reserved name in documentation with a future-scope note

### Future Aloe trigger condition

> Aloe Desktop becomes a public brand only when:
> dimarch-taskbar + dimarch-desktop-layer + dimarch-control-center
> can be installed and used on a clean Hyprland system
> without the full DimArch OS installer.

---

## Full Brand Map

```
DimArch OS                    ← the system / distribution / installer
├── Sage                      ← visual identity / design language / theme
│   └── dimarch-theme repo
├── dimarch-taskbar            ← bottom panel (Python + GTK4)
├── dimarch-desktop-layer      ← future: desktop icons, right-click
├── dimarch-daycenter          ← future: calendar, tasks, mini-CRM
├── dimarch-control-center     ← future: settings GUI
└── dimarchctl                 ← CLI control layer

Reserved:
└── Aloe Desktop               ← future brand if components go standalone
```

---

## README Template Text

```markdown
# DimArch OS

**Modern system. Old soul.**

DimArch OS is an opinionated Arch Linux desktop system: calm by design,
fast by default, and structured as a complete daily system rather than
a pile of dotfiles.

DimArch means **Dimmed Arch** — a quieter, more deliberate Arch desktop.
Dimmed, not dumbed down.

The system uses the **Sage** visual identity: calm, clean, and rooted.
```

---

*DimArch OS — Dimmed Arch. Modern system. Old soul.*
