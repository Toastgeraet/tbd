# Contributing to the scaffold skill

For Claude sessions and humans alike. `scaffold` is one skill of the **tbd**
plugin, which lives in its own git repository, the *dev repo*:

- On Tobi's PC: `C:\Users\Tobi\Documents\tbd`
- Anywhere else: `git clone git@github.com:Toastgeraet/tbd.git`. In a Claude
  cloud session, attach `Toastgeraet/tbd` to the session with push access
  first (`add_repo`), or the GitHub proxy won't serve it — see
  [reference/claude-cloud.md](reference/claude-cloud.md#editing-the-skill-from-a-cloud-session).

This skill is at `plugins/tbd/skills/scaffold/` in it; every path below is
relative to that folder.

**Edit the dev repo, never the installed copy.** Claude Code installs plugins into
a cache under `~/.claude/plugins/` and replaces that copy on every update, so edits
there are silently lost. If this skill's base directory is under
`~/.claude/plugins/`, you are looking at the cache.

```bash
DEV=~/Documents/tbd        # wherever the dev repo is cloned
git -C "$DEV" status
git -C "$DEV" add -A
git -C "$DEV" commit -m "scaffold/<stack-id>: <what changed>"
```

Ask the user before editing, and push only when asked. Once pushed, every machine
picks the change up with `/plugin marketplace update toastgeraet`, or by itself if
auto-update is on for the marketplace.

## What belongs here

Write down what would have saved time:

- **Exact, working commands and settings**, with the versions they ran on.
- **Pitfalls as symptom → cause → fix.** The symptom matters most: it is what the
  next session will see first. "Black page in the browser, server log shows only
  `GET /`" is findable; "server needs threading" is not.
- **Decisions and why**, especially ones that were reversed.
- **Environment facts** — tool paths, installed SDKs — labelled with the machine
  they belong to.

Leave out:

- Generic tutorial material Claude already knows.
- Business logic of the project the knowledge came from.
- **Secrets, and anything you wouldn't publish.** The repository is public on
  GitHub. Never commit keystores, signing passwords, API tokens or `.env`
  contents. Write down *where* a secret lives and how it is provided (for
  example "EAS token is a GitHub Actions secret named `EXPO_TOKEN`"), never the
  value. Keep private project details out too.

## Status labels

Every stack README, and every file inside a stack, opens with a status line:

```markdown
> **Status:** proven · **Last verified:** 2026-11-01, Godot 4.7.2 · **Proven in:** cosmic-capitalist
```

| Label | Means | Rule |
| --- | --- | --- |
| **proven** | Done end-to-end in a real project. | Name the project. |
| **verified** | Exercised in a throwaway test, not yet in a real project. | Say what the test was. |
| **researched** | Believed true from docs or knowledge, never run here. | Treat it as a plan; verify before relying on it. |
| **superseded** | Used to be the way; no longer is. | Keep only if it explains a trap, under a *History* heading. |

When a file mixes levels, label the sections. Never upgrade a label without having
run the thing. When you rely on researched information, re-check it and upgrade
or correct it.

## Adding a stack

1. Pick an id: kebab-case, named after what it builds and with what —
   `expo-android`, `fastapi-service`, `astro-site`.
2. Copy the template: `cp -r stacks/_template stacks/<id>`.
3. Fill in `stacks/<id>/README.md`. Keep it a map: status, when to choose it,
   questions to ask, the scaffold steps, verification, and links to deeper files.
   Move long material into sibling files (`verification.md`, `android-build.md`,
   …) so a session reads only what it needs.
4. Optional: `stacks/<id>/templates/` with files to copy into new projects.
   - Use `__PROJECT_NAME__` as the placeholder.
   - Name dotfiles `gitignore.txt`, `gitattributes.txt` and so on — a real
     `.gitignore` inside this repository would apply to the repository itself.
   - Prefer files copied from a project where they worked over hand-written ones.
5. Add a row to the **Stack index** in `SKILL.md`, or update the existing
   "not yet written up" row.
6. Cloud facts — what built where, what network access was needed — go in the
   stack *and*, if they generalise, in `reference/claude-cloud.md`.
7. Commit with `scaffold/<id>: add stack`.

## Updating a stack

Edit in place, update **Last verified**, and adjust the status label if it changed.
If you correct something, say so in the commit message — the old text may already
have misled a session somewhere.

## Size discipline

Claude loads `SKILL.md` whenever the skill triggers, and other files only when it
follows a link. Keep `SKILL.md` under about 200 lines and each stack README under
about 250. Split anything longer into linked files rather than trimming useful
detail.

## Writing a stack up from another project's session

A session in some other project — one that already *knows* the stack because it
built something with it — is the best author. Paste this there, with the
placeholders filled in:

```text
Read CONTRIBUTING.md and SKILL.md of the tbd:scaffold skill, then edit them in
the plugin's dev repo, not the installed copy: C:\Users\Tobi\Documents\tbd
on Tobi's PC, otherwise clone git@github.com:Toastgeraet/tbd.git. Write up
the stack this project uses as a new stack in that skill, id `<stack-id>`:

- Copy stacks/_template to stacks/<stack-id> and fill it in from what this
  project actually did: versions, the setup steps in order, how it is built
  and delivered, how it is verified, and every pitfall that cost time
  (symptom -> cause -> fix). Use this repository and its git history as the
  source, not general knowledge.
- Label everything proven / verified / researched as CONTRIBUTING.md defines.
  Only things this project really ran are proven.
- Cover what ran in Claude cloud sessions versus locally, and add anything
  that generalises to reference/claude-cloud.md.
- Add templates/ only for files that are reusable as-is.
- Never copy secrets; record where they live instead.
- Update the stack's row in the SKILL.md index.

Show me the changes before committing them in the dev repo.
```

For the reading tracker, use the id `expo-android`. Its row already exists in the
index, marked "not yet written up".
