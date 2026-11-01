# tbd — Tobias Bergmann Development

A Claude Code plugin of living skills. Each skill is called `/tbd:<skill>`, and
each one grows as projects teach it something.

| Skill | What it does |
| --- | --- |
| `/tbd:scaffold` | Asks what you want to build — Android app, Godot game, both, web project, service — and sets it up from a stack that has already been proven: Godot (desktop, web, headless tests) and Expo Android (EAS builds, OTA updates from cloud sessions). |
| `/tbd:contribute` | Looks back over the current session for anything worth adding to these skills, lets you pick, and opens a pull request here with it. |

You don't need to type the commands: "start a new Godot game" or "anything from
this session worth adding to tbd?" trigger them too.

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

The `claude` command comes with the standalone CLI, not with the desktop app. On
Windows, install it with `irm https://claude.ai/install.ps1 | iex` and open a new
terminal; it shares `~/.claude` with the desktop app, so plugins and settings
apply to both. The desktop app's own copy,
`%APPDATA%\Claude\claude-code\<version>\<hash>\claude.exe`, is not on PATH and
moves with every app update.

### Cloud sessions

**This install does not reach Claude cloud sessions.** A cloud session loads no
plugin you install yourself — neither one installed on your machine nor one a
repository's `.claude/settings.json` declares. The options for getting the skills
there, none tried yet, are in
[plugins/tbd/skills/scaffold/reference/claude-cloud.md](plugins/tbd/skills/scaffold/reference/claude-cloud.md#using-the-skill-in-a-cloud-session).

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

- Changes go through pull requests: `/tbd:contribute` in any session collects
  what it learned and opens one. Merging is the review step — with auto-update,
  a merge reaches every machine.
- Skills live in `plugins/tbd/skills/<name>/SKILL.md`. A new folder there
  becomes `/tbd:<name>`; add it to the table above.
- Each skill can have its own contributing guide. The scaffold skill's is
  [plugins/tbd/skills/scaffold/CONTRIBUTING.md](plugins/tbd/skills/scaffold/CONTRIBUTING.md),
  including a prompt for writing a stack up from another project's session.
- **Edit this repository, never the installed copy** in `~/.claude/plugins/` —
  updates replace it.
- Check the structure after changes: `claude plugin validate .` and
  `claude plugin validate ./plugins/tbd`. Expect the warning "No version
  specified" — that is the deliberate choice above — and, from CLI 2.1.3xx on,
  plugin-directory warnings such as a missing icon, which only matter for a
  submission to Anthropic's plugin directory.
- Try a change without installing anything:
  `claude --plugin-dir ./plugins/tbd plugin details tbd` lists the skills it finds.

## Layout

```
.claude-plugin/marketplace.json     the marketplace "toastgeraet"
plugins/tbd/.claude-plugin/plugin.json
plugins/tbd/skills/scaffold/        SKILL.md, CONTRIBUTING.md, stacks/, reference/
plugins/tbd/skills/contribute/      SKILL.md
```
