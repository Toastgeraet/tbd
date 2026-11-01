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

### Cloud sessions

**This install does not reach Claude cloud sessions.** A cloud session loads no
plugin you install yourself — neither one installed on your machine nor one a
repository's `.claude/settings.json` declares. The options for getting the skills
there, none tried yet, are in
[plugins/tbd/skills/scaffold/reference/claude-cloud.md](plugins/tbd/skills/scaffold/reference/claude-cloud.md#getting-this-skill-into-a-cloud-session).

### Optional: load from a local clone

To see edits without pushing, register a clone of this repository instead of
GitHub:

```text
/plugin marketplace add C:\Users\Tobi\Documents\tbd
/plugin install tbd@toastgeraet
```

Claude Code then loads the plugin **in place**: edits take effect at the next
session start or after `/reload-plugins`, with no push and no update step. A
machine can register only one marketplace named `toastgeraet`, so use either this
or the GitHub one.

## Update

Turn on auto-update once per machine, and sessions pick up new commits by
themselves: a few minutes after the first message, Claude Code fetches the
marketplace and shows "Plugin updated: tbd · Run /reload-plugins to apply".
Auto-update is **off by default** for marketplaces like this one. Either use
`/plugin` → **Marketplaces** → `toastgeraet` → **Enable auto-update**, or set it
in `~/.claude/settings.json`:

```json
"extraKnownMarketplaces": {
  "toastgeraet": {
    "source": { "source": "github", "repo": "Toastgeraet/tbd" },
    "autoUpdate": true
  }
}
```

To update right away: `/plugin marketplace update toastgeraet` in a session, or
`claude plugin update tbd@toastgeraet` from a shell. (`claude plugin marketplace
update` without a name refreshes the listing only, not the installed plugin.)

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
