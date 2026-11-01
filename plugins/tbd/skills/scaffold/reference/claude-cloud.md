# Claude cloud sessions — what they can and cannot do

> **Status:** proven where marked (from reading-tracker, Expo, 2026-10-06 to 2026-11-01) · researched otherwise · **Last checked:** 2026-11-01

Stack-independent facts about developing in a Claude cloud session connected to
GitHub. The `expo-android` stack was built almost entirely this way; its
[cloud.md](../stacks/expo-android/cloud.md) has the stack-specific detail.

## The environment

- A Linux container managed by Anthropic, with the GitHub repository cloned into
  it. The session can commit, push branches and open pull requests. **proven**
- **Ephemeral.** Each new session starts clean: `node_modules` and anything else
  installed is gone. A committed SessionStart hook in `.claude/settings.json` can
  reinstall; guard it with `[ "$CLAUDE_CODE_REMOTE" = "true" ]` so it never runs
  on the user's PC. `npm ci` took about 20 seconds for an Expo app. **proven**
  (hook verified on a clean copy)
- **Outbound traffic goes through a proxy.** In reading-tracker's environment the
  npm registry and GitHub worked, but some vendor APIs and doc sites were refused
  (`api.expo.dev`: "HTTP Proxy Network Error: Forbidden"; `curl` to
  docs.expo.dev: "CONNECT tunnel failed, response 403"). Look for the tool's
  offline mode first (`EXPO_OFFLINE=1`), then a connector. **proven**
- **Preinstalled** (reading-tracker's container): Node 22.22, npm 10.9, Python 3,
  Playwright 1.56.1 under `/opt/node-tools`, Chromium under `/opt/pw-browsers`
  (don't run `playwright install`). Enough for headless browser screenshots of
  web builds. **proven**
- **CPU only.** No GPU, so anything that renders needs software rendering, and
  is slow. Headless Chromium screenshots worked fine. **proven** for the browser
- **No hardware virtualisation** (as far as known), so Android emulators are out.
  Testing on a real device stays with the user.

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
| Godot (researched) | edit, headless import + tests, push | GitHub Actions | APK artifact or release |

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

## Using this skill in a cloud session

This skill ships in the `tbd` plugin. Plugins installed for the user on their PC
are **not** present in a cloud session. The documented way to give one repository
the plugin is to register the marketplace at project scope and commit the result:

```bash
claude plugin marketplace add Toastgeraet/tbd --scope project   # writes .claude/settings.json
```

The repository is public, so the clone needs no credentials. Still untested in a
cloud session — record here what actually works.

**proven** (attach, clone, edit; 2026-11-01): to *edit* the skill from a cloud
session working in another project, attach the dev repo to the session
(`add_repo` for `Toastgeraet/tbd` with push access), clone it next to the
project, edit and commit there. The `expo-android` stack was written up this way.

## Before relying on the cloud for a new stack, find out

1. Which toolchain downloads it needs, their size, and whether the proxy allows
   them (or whether the tool has an offline mode).
2. Whether tests can run headless on CPU.
3. What has to build elsewhere, how the session starts it (connector, CI), and
   how the artefact reaches the user.
4. Which secrets the build needs, and where they live (build-service account,
   repository secrets). Never in git, and preferably not in the session either.
5. Which one-time steps need the user (accounts, linking, interactive key
   generation), so they can be asked for up front.
