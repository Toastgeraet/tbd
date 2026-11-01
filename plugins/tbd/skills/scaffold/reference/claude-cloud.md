# Claude cloud sessions — what they can and cannot do

> **Status:** proven where marked (from reading-tracker, Expo, 2026-10-06 to
> 2026-11-01, and rechen-trainer, Godot, 2026-11-01) · researched otherwise — the researched parts were checked against
> the Claude Code docs on 2026-11-01 (code.claude.com: cloud-environments,
> plugins/install, plugins/loading, skills) · **Last checked:** 2026-11-01

Stack-independent facts about developing in a Claude cloud session connected to
GitHub. The `expo-android` stack was built almost entirely this way; its
[cloud.md](../stacks/expo-android/cloud.md) has the stack-specific detail.

## The environment

- A Linux container managed by Anthropic, with the GitHub repository cloned into
  it. The session can commit, push branches and open pull requests. **proven**
  The docs specify a fresh VM per session, Ubuntu 24.04 on x86_64 — use x86_64
  Linux builds of any binary tool. *researched*
- **Ephemeral.** Each new session starts clean: `node_modules` and anything else
  installed is gone. A committed SessionStart hook in `.claude/settings.json` can
  reinstall; guard it with `[ "$CLAUDE_CODE_REMOTE" = "true" ]` so it never runs
  on the user's PC. `npm ci` took about 20 seconds for an Expo app. **proven**
  (hook verified on a clean copy)
- **Setup scripts and caching.** An environment can also run a Bash setup script
  before Claude Code starts. If it finishes within about five minutes, the
  filesystem is snapshotted and later sessions start from that snapshot, skipping
  the script; the snapshot is rebuilt when the script changes and about every
  seven days. Use it for toolchains; use a SessionStart hook for per-project
  setup that should also run locally. *researched*
- **Outbound traffic goes through a proxy.** In reading-tracker's environment the
  npm registry and GitHub worked, but some vendor APIs and doc sites were refused
  (`api.expo.dev`: "HTTP Proxy Network Error: Forbidden"; `curl` to
  docs.expo.dev: "CONNECT tunnel failed, response 403"). Look for the tool's
  offline mode first (`EXPO_OFFLINE=1`), then a connector. **proven**
  This matches the documented default network level, *Trusted*: package
  registries, GitHub and cloud SDKs only. The *Custom* level takes your own domain
  list and could admit hosts like these. *researched*
- **GitHub goes through its own proxy**, which holds the real credentials. It
  refuses tag pushes and branch deletions. GitHub API requests work only for
  repositories *attached to the session*, and source archives
  (`github.com/<owner>/<repo>/archive/…`, `codeload.github.com`) of unattached
  repositories are refused even when public. `gh` is pre-installed, but GraphQL
  subcommands (`gh pr`, `gh issue`) are refused; `gh api` (REST) works.
  *researched* — except: **tag pushes are refused**, **proven** (rechen-trainer,
  2026-11-01): `git push origin v0.1.0` gave `RPC failed; HTTP 403` and then
  printed "Everything up-to-date", which looks like success, while branch pushes
  to the same repo worked. Check with `git ls-remote --tags origin`. Make the tag
  on the user's PC (`git tag -a vX.Y.Z <sha> -m …` + `git push origin vX.Y.Z`) or
  on GitHub's *Draft a new release* page.
- **`gh` may have no working login.** In rechen-trainer's container `gh auth
  status` reported "The token in GH_TOKEN is invalid", so `gh api` was
  unavailable as well. **proven** for that session.
- **Preinstalled** (reading-tracker's container): Node 22.22, npm 10.9, Python 3,
  Playwright 1.56.1 under `/opt/node-tools`, Chromium under `/opt/pw-browsers`
  (don't run `playwright install`). Enough for headless browser screenshots of
  web builds. **proven**
- **CPU only.** No GPU, so anything that renders needs software rendering, and
  is slow. Headless Chromium screenshots worked fine. **proven** for the browser
- **No hardware virtualisation** (as far as known), so Android emulators are out.
  Testing on a real device stays with the user.

## What a cloud session loads from your setup

*researched* (docs, 2026-11-01):

| Source | Loads in a cloud session? |
| --- | --- |
| Repo `CLAUDE.md`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/` | Yes — part of the clone (a *project's* cloud threads load less) |
| Repo `.claude/settings.json` hooks and permissions, `.mcp.json` | Yes, in a session with one repository |
| Plugins and marketplaces declared in the repo's `.claude/settings.json` | **No** — this needs the workspace-trust dialog, which cloud sessions never show |
| Plugins installed on your machine (`~/.claude/settings.json`) | **No** — but see the observation below |
| Your `~/.claude/CLAUDE.md` and `~/.claude/skills/` | **No** — they live on your machine |
| Skills enabled on your claude.ai account | **Yes**, synced at session start |
| Organisation server-managed settings, including plugins | Yes — needs a Team/Enterprise Owner |

## Reaching services without putting secrets in the session

**proven:** connectors (claude.ai MCP servers) act with the user's own account, so
no token lives in the container. The Expo connector started EAS builds and EAS
workflows, read their status and logs, and read the docs; the GitHub tools
watched Actions runs. Prefer this over adding an API token to the environment.

What a connector can't do still needs the user once: creating the service-side
project, linking it to GitHub, and anything interactive (Expo's first build
generating the signing key).

## Waiting on long external jobs

**proven:** free-tier build queues waited from minutes to over three hours.
Don't sleep or poll in a loop. Schedule a check-in for the session itself
(`send_later`, 15–30 minutes), report only when the state changed, and note that
"queued with no change for an hour" was normal, not a hang.

## The pattern that works

Keep the session light; send heavy native builds elsewhere; deliver the artefact
to the user's device.

| Stack | Session does | Heavy build runs on | Delivery |
| --- | --- | --- | --- |
| `expo-android` (**proven**) | edit, test, web-preview screenshots, push, start builds and OTA publishes via the Expo connector | Expo EAS (builds and update workflows) | APK link on the phone, then over-the-air updates |
| Godot (**proven** without CI) | download Godot, edit, headless import + tests, probes and Xvfb screenshots, push | the user's PC, from the editor | Remote Deploy over wireless adb; APK attached to a GitHub Release |
| Godot (researched with CI) | same | GitHub Actions | APK artifact or release |

A cheap gate in GitHub Actions (tests, typecheck, lint on every push) before
anything ships to phones costs nothing in the build service's queue. **proven**

## The user's own computer

- A cloud session can't reach it. The user pulls the branch and runs the few
  commands that need their machine. **proven**
- Remote Control can attach a folder on the user's computer to a cloud session,
  but only on Mac or Linux, not Windows. **researched** (tool description; the
  user's Windows PC offered no folders)
- **Windows line endings break hashes.** Git's `core.autocrlf` checked out CRLF,
  which changed a content hash computed on the PC (Expo's runtime fingerprint)
  versus the same commit on Linux. Commit `.gitattributes` with
  `* text=auto eol=lf` in every project that hashes files. **proven**

## Handing over between sessions

**proven:** sessions get reset; the repository is the memory. A short `CLAUDE.md`
with rules that must not break, plus `.claude/docs/` (architecture, a release log
with every build and update ID, roadmap, decisions already made, plans) and a
project skill for shipping, let fresh sessions continue features and releases
without re-asking.

## This skill and cloud sessions

### Editing the skill from a cloud session

**proven** (attach, clone, edit; 2026-11-01): to *edit* the skill from a cloud
session working in another project, attach the dev repo to the session
(`add_repo` for `Toastgeraet/tbd` with push access), clone it next to the
project, edit and commit there. The `expo-android` stack was written up this way.

### Using the skill in a cloud session

**Observed, contradicting the table** (rechen-trainer, 2026-11-01): in a cloud
session started with no repository, `tbd:scaffold` was available and loaded.
The container's user-scope `~/.claude/settings.json` declared the `toastgeraet`
marketplace and `"enabledPlugins": {"tbd@toastgeraet": true}`. The file was
written at container start, and the plugin was installed into
`~/.claude/plugins/cache/` at that moment, **pinned to the then-latest commit**.
So something installs the plugin per session. *Which* mechanism (account-level
plugin sync, the environment's configuration, or something else) wasn't
identified. Find out before relying on it, then rewrite this section and the
table. Practical consequences seen:

- The installed copy can lag `main` (here by two commits, including a changed
  contribution process). For contributing, read the dev repo's `origin/main`,
  not the cache.
- The `/tbd:contribute` skill wasn't in that copy yet, but the dev repo had it.

Options considered before this was observed, none tried yet:

1. **Enable the skill on your claude.ai account** — upload it via *Customize* in
   the desktop app's sidebar, or claude.ai's skill settings. This is the
   documented route. It then loads in cloud sessions, and terminal sessions
   signed in with that account sync it into `~/.claude/skills/synced/`. Open
   questions and costs:
   - Upload accepts only the frontmatter keys `name`, `description`, `license`,
     `compatibility`, `metadata` and `allowed-tools`. This SKILL.md uses only the
     first two.
   - Whether a multi-file skill — this one has dozens of files in subfolders,
     templates included — uploads intact is not documented.
   - It is a second update path: every change needs a re-upload, separate from
     git and `/plugin`.
   - It loads as `scaffold`, not `tbd:scaffold`, and would load twice on a
     machine that also has the plugin.
2. **An environment setup script** that fetches this repository inside the VM and
   either runs `claude plugin marketplace add Toastgeraet/tbd` plus
   `claude plugin install tbd@toastgeraet`, or copies the skill into
   `~/.claude/skills/scaffold/`. The docs show a setup script writing
   `~/.claude/CLAUDE.md` and that file being loaded; whether plugins or skills
   written the same way load is not documented. Catches: the GitHub proxy may
   refuse to clone a repository that isn't attached to the session (attaching it
   worked for editing, above), and the cached snapshot means updates can lag by
   up to a week unless the script changes.
3. **Commit a copy into a project's `.claude/skills/`.** Loads for that repository,
   but every copy drifts from the source — avoid it for a living skill.
4. **Organisation managed settings** — only with a Team or Enterprise plan and an
   Owner role.

Try option 1 first. When something works, record it here as **proven** and
update the install section of the repository README.

## Before relying on the cloud for a new stack, find out

1. Which toolchain downloads it needs, their size, and whether the proxy allows
   them (or whether the tool has an offline mode) — and whether a setup script
   can install them within five minutes so the environment caches.
2. Whether tests can run headless on CPU.
3. What has to build elsewhere, how the session starts it (connector, CI), and
   how the artefact reaches the user.
4. Which secrets the build needs, and where they live (build-service account,
   repository secrets). Never in git, and preferably not in the session either.
5. Which one-time steps need the user (accounts, linking, interactive key
   generation), so they can be asked for up front.
