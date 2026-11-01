# scaffold — a living Claude Code skill for starting projects

Ask Claude to start a new project and this skill asks what you want to build —
an Android app, a Godot game, both, a web project, a service — then sets it up
from a stack that has already been proven, rather than rediscovering the setup
each time. Every project that teaches something new about its stack writes that
back here, so the next one starts further ahead.

| Stack | Status |
| --- | --- |
| Godot 4 game | proven (desktop, web, headless tests); Android and cloud builds researched |
| Expo Android app | proven in the reading tracker; not yet written up |

## Install

Claude Code loads personal skills from `~/.claude/skills/<name>/SKILL.md`. The
install **is** a clone of this repository at that path — one copy, edited in
place, nothing to keep in sync.

Windows (PowerShell):

```powershell
git clone git@github.com:Toastgeraet/claude-scaffold.git "$HOME\.claude\skills\scaffold"
```

macOS / Linux / a cloud session's setup script:

```bash
git clone git@github.com:Toastgeraet/claude-scaffold.git ~/.claude/skills/scaffold
```

New sessions pick it up; a running session usually notices it within moments. It
must sit at exactly `~/.claude/skills/scaffold` — `SKILL.md` has to be one level
below `skills/`.

## Update

```powershell
~\.claude\skills\scaffold\scripts\update.ps1
```

```bash
~/.claude/skills/scaffold/scripts/update.sh
```

Both fetch, refuse to touch uncommitted edits, warn about local commits that
haven't been pushed (knowledge other machines are missing), and fast-forward to
the latest version.

## Use

Say what you want — "start a new Godot game", "set up a new project" — or type
`/scaffold`.

## Extend it

Read [CONTRIBUTING.md](CONTRIBUTING.md). The short version: copy
`stacks/_template` to `stacks/<id>`, fill it in from a project that really did it,
label everything proven / verified / researched, add a row to the index in
[SKILL.md](SKILL.md), and commit here.

The best author for a stack is a session in a project that already uses it.
CONTRIBUTING.md has a prompt to paste into that session.

## Layout

```
SKILL.md                  entry point: the workflow and the stack index
CONTRIBUTING.md           how to add and update stacks; status labels
stacks/_template/         starting point for a new stack
stacks/godot/             Godot 4: docs, templates/, recipes/
reference/                cross-stack: workflow preferences, Claude cloud, process
scripts/update.(ps1|sh)   pull the latest version safely
```
