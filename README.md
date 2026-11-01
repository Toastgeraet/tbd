# tbd — Tobias Bergmann Development

A Claude Code plugin of living skills. Each skill is called `/tbd:<skill>`, and
each one grows as projects teach it something.

| Skill | What it does |
| --- | --- |
| `/tbd:scaffold` | Asks what you want to build — Android app, Godot game, both, web project, service — and sets it up from a stack that has already been proven. Godot is proven (desktop, web, headless tests); Expo Android is proven in the reading tracker but not written up yet. |

You don't need to type the command: "start a new Godot game" triggers it too.

## Install

This repository is a plugin **marketplace** named `toastgeraet`, holding one
plugin, `tbd`. In a Claude Code session:

```text
/plugin marketplace add Toastgeraet/tbd
/plugin install tbd@toastgeraet
```

Or from a shell:

```bash
claude plugin marketplace add Toastgeraet/tbd
claude plugin install tbd@toastgeraet
```

The repository is public, so no credentials are needed. Claude Code clones over
SSH when the machine has a GitHub SSH key, and over HTTPS otherwise — but on a
machine with **no** GitHub SSH key, set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`,
because installs and updates started inside a session don't fall back to HTTPS on
their own.

If `claude` is not on your PATH, the desktop app bundles one at
`%APPDATA%\Claude\claude-code\<version>\<hash>\claude.exe`.

### On the machine you develop on

Register the dev folder instead of GitHub:

```text
/plugin marketplace add C:\Users\Tobi\Documents\tbd
/plugin install tbd@toastgeraet
```

Claude Code then loads the plugin **in place**: edits take effect at the next
session start or after `/reload-plugins`, with no push and no update step. A
machine can register only one marketplace named `toastgeraet`, so use either this
or the GitHub one.

## Update

```text
/plugin marketplace update toastgeraet
```

Or turn on auto-update once — `/plugin` → **Marketplaces** → `toastgeraet` →
**Enable auto-update** — and sessions pick up new commits by themselves.

`plugin.json` deliberately has **no `version`**, so every pushed commit counts as
an update. If you ever add a `version`, nobody receives a change until you bump it.

## Develop

- Skills live in `plugins/tbd/skills/<name>/SKILL.md`. A new folder there
  becomes `/tbd:<name>`; add it to the table above.
- Each skill can have its own contributing guide. The scaffold skill's is
  [plugins/tbd/skills/scaffold/CONTRIBUTING.md](plugins/tbd/skills/scaffold/CONTRIBUTING.md),
  including a prompt for writing a stack up from another project's session.
- **Edit this repository, never the installed copy** in `~/.claude/plugins/` —
  updates replace it.
- Check the structure after changes: `claude plugin validate .` and
  `claude plugin validate ./plugins/tbd`. Expect exactly one warning, "No version
  specified" — that is the deliberate choice above.
- Try a change without installing anything:
  `claude --plugin-dir ./plugins/tbd plugin details tbd` lists the skills it finds.

## Layout

```
.claude-plugin/marketplace.json     the marketplace "toastgeraet"
plugins/tbd/.claude-plugin/plugin.json
plugins/tbd/skills/scaffold/        SKILL.md, CONTRIBUTING.md, stacks/, reference/
```
