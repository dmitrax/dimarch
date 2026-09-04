# Agent skill — teaching a coding agent this system

DimArch ships a skill for coding agents (Claude Code and anything else reading
`~/.claude/skills`). Deployed by `install/phases/06-dotfiles.sh` STEP 12 from
`dotfiles/claude/.claude/skills/dimarch/`.

---

## Why this exists

An agent asked to "bind Super+E to the file manager" or "make the bar accent
brighter" will do it — from general knowledge, on a system that has specific
rules. Three of those rules have cost real debugging time here:

- **`~/.config/` and the repository are separate files with no sync.** An agent
  edits `dotfiles/hypr/…`, reports success, and the live system never changes.
  This happened twice before the rule was written down.
- **Colour is not chosen locally.** Every value resolves from `dimarch-theme`
  through the `palette` tool. Picking a similar-looking hex is how one palette
  quietly became three by mid-2026.
- **`sudo` does not work from an agent session, `pkexec` does.** Without knowing
  that, an agent either gives up on every system task or tries `sudo` variants
  that cannot succeed.

None of this is discoverable from the code. Before this skill it lived in a
`CLAUDE.md` that is gitignored — visible to the author, invisible to everyone
running DimArch.

---

## What it contains

```
~/.claude/skills/dimarch/
├── SKILL.md       boundaries, privileges, discovery, decision framework
├── hyprland.md    the Lua config, live-API checking, the rebinding ritual
└── theming.md     palette rules, the unset-key trap, transparency
```

The two guides are read only when a request touches them — the entry point stays
short, and a question about idle timeouts does not pull in Hyprland's Lua API.

### The rules it carries

| Rule | Why |
|---|---|
| Edit `~/.config/` first, mirror to the repo after | A repo edit does not reach the running system |
| Resolve colour through `palette`, finish with `palette check` | The map is the only thing that can catch a drifted value |
| Check the live Hyprland API (`hyprctl repl`) before writing a dispatcher | The Lua API has moved between releases |
| `hyprctl binds` before rebinding, and say what the key did before | A silently stolen binding is found days later |
| `pkexec` for root, announced, with a timeout, once per job | The password dialog appears over the user's work, and there is no auth cache |
| `dimarchctl commands --json` instead of recalling syntax | The CLI describes itself; memory does not |

### What it deliberately does not do

- **It is not for developing DimArch.** Writing install phases, adding package
  repositories, authoring migrations — that has its own rules in the repository.
  The skill says so explicitly, because a skill that covers everything gets
  invoked for everything and stops meaning anything.
- **It does not launch agents with permissions disabled.** Omarchy, whose
  delivery model this borrows, starts them in auto-approve modes from a
  keybinding. DimArch does not: a destructive action gets a one-line warning
  first.

---

## How it's wired in

`06-dotfiles.sh` STEP 12 runs `deploy_dotfile_tree "claude"`, which copies the
tree into `$HOME` preserving paths. The same step carries the Claude Code colour
theme (`dotfiles/claude/.claude/themes/dimarch-sage.json`).

Claude Code itself is **not installed** by this step — it is optional software,
and a machine that never runs it simply carries two unused files.

### Copy today, symlink later

The skill is a copy. When `dimarch_repo` lands, it moves to
`/usr/share/dimarch/agents/skills/dimarch/` and `~/.claude/skills/dimarch`
becomes a symlink — so `pacman -Syu` updates the skill itself, the way Omarchy
does it. Only the install step changes then; the skill's text does not, because
it describes boundaries that hold under both layouts.

---

## Privileges: `pkexec`, not `sudo`

Verified on this machine 2026-09-04.

`sudo` fails from an agent session: there is no controlling tty, and sudo's
ticket is bound to one, so `sudo -n` fails even when the same user's `sudo -l -n`
succeeds a second earlier.

`pkexec` works. polkit raises a graphical dialog through `hyprpolkitagent`, the
user types their password, the command runs as root:

```
hyprpolkitagent REQUEST → COMPLETED
pam_unix(polkit-1:session): session opened for user root(uid=0) by <user>(uid=1000)
```

Consequences the skill states as rules:

- The dialog appears over whatever the user is doing, so an unannounced
  `pkexec` is indistinguishable from something hostile. Say it first.
- There is **no auth cache** — a second call a minute later asks again. Root-side
  work goes into one script and elevates once, not in a loop.
- Wrap it in `timeout`: if the dialog is missed, the call waits indefinitely.

This is not passwordless root and does not replace it. A human approves every
call; the change is that approval takes five seconds instead of switching
terminals.

---

## Known limitations

- **New and narrow.** It says where things live and which shortcuts break; it
  does not make a desktop change safe on its own. Plan mode is still the right
  default for anything spanning several files.
- **The vendor half of the boundary is not written yet.** `/usr/share/dimarch/`
  does not exist, so the skill describes today's split — user config versus
  repository — and gains the packaged half when the package does.
- **Different models use a skill to different effect.** Upstream Omarchy says the
  same about theirs, and it is worth repeating rather than discovering.
- **Not portable to the Mac setup.** `mac-setup` is a separate repository, and a
  skill about Hyprland and pacman has nothing to say there.
