# Expo Android — Claude cloud sessions

> **Status:** proven, except where marked · **Last verified:** 2026-10-09 · **Proven in:** reading-tracker

reading-tracker was built from the user's phone in the Claude app: cloud sessions did the work, Expo's
servers did the native builds and update publishing, and the PC was needed only for the one-time EAS setup.
Stack-independent facts are in [../../reference/claude-cloud.md](../../reference/claude-cloud.md).

## What ran where

| Task | Ran in | How |
| --- | --- | --- |
| Scaffold, code, `npm install`, `expo install` | cloud | `EXPO_OFFLINE=1` for Expo CLI commands |
| Tests, typecheck, lint, Android bundle check | cloud | plain CLI |
| Web preview + screenshots | cloud | `expo export --platform web`, `python3 -m http.server`, preinstalled Playwright/Chromium |
| Runtime fingerprint | cloud | `npx expo-updates fingerprint:generate` (offline, works) |
| Commit, push, merge to `main` | cloud | git; GitHub via the GitHub MCP tools |
| Create the EAS project, link GitHub | **user**, expo.dev / PC | needs an Expo login |
| First APK build (creates the keystore) | **user's PC** | `eas build`, interactive keystore prompt |
| Later APK builds | Expo servers, started from cloud | connector `build_run` on a pushed branch |
| First OTA publishes | **user's PC** | `eas update` (before the workflow existed) |
| OTA publishes since 2026-10-07 | Expo servers, started from cloud | connector `workflow_run` with `publish-update.yml` |
| Checks gate before publishing | GitHub Actions | `checks.yml`, watched with `actions_list` / `actions_get` |
| Install APK, receive OTA, device checks | **user's phone** | — |

## Network and tools in the container

- **`api.expo.dev` is blocked** by the session's proxy (`HTTP Proxy Network Error: Forbidden`). npm
  registry access works. `EXPO_OFFLINE=1` makes `expo install` use the SDK's bundled version list, and
  `expo export` and the fingerprint CLI run offline anyway.
- **`eas` CLI can't log in.** No Expo token was ever put in the environment. The **Expo connector**
  (claude.ai MCP, `mcp__Expo__*`) did everything that needs the account: builds (`build_run`,
  `build_info`, `build_list`, `build_logs`), workflows (`workflow_run`, `workflow_info`, `workflow_logs`,
  `workflow_validate`) and documentation (`search_documentation`, `read_documentation`).
- **`curl` to docs.expo.dev returned 403** through the proxy. Read Expo docs with the connector's
  `read_documentation` instead (it also takes `.md` URLs and an `offset` for long pages).
- **Preinstalled:** Node 22.22, npm 10.9, Python 3, Playwright 1.56.1 under `/opt/node-tools`, Chromium
  under `/opt/pw-browsers` (`PLAYWRIGHT_BROWSERS_PATH` set; don't run `playwright install`).
- **Ephemeral:** `node_modules` is gone in a new session. `templates/claude/settings.json` has a
  SessionStart hook that runs `npm ci` when it's missing, only when `CLAUDE_CODE_REMOTE=true` (so it never
  runs on the user's PC). **verified:** about 20 seconds on a clean copy; not timed in later sessions.

## Waiting on Expo without polling

Builds and workflow runs can wait in the free queue for hours. Sessions scheduled a check-in
(`send_later`, 15–30 minutes) and reported only when something changed, instead of sleeping or polling.

## The user's PC (Windows)

- A cloud session can't reach it. The user pulls the branch and runs commands in Git Bash when needed.
  (Remote Control folders on the user's computers can be attached to a cloud session, but only from Mac or
  Linux, not Windows — **researched**, from the tool description; never used.)
- **Line endings:** Git on Windows (`core.autocrlf=true`) checked out CRLF, which changed the runtime
  fingerprint, so the user's first `eas update` went to a runtime no APK has. `.gitattributes` with
  `* text=auto eol=lf` fixed it; an existing clone needed `git rm --cached -r -q . && git reset --hard` once.

## Handing over between sessions

Sessions were reset often. What kept them productive: a short `CLAUDE.md` with hard rules (always say
whether a change ships as OTA or needs an APK, never change the package/owner/projectId, schema
migrations, strings in both languages, run the checks), detail in `.claude/docs/` (architecture, a
releases log with every build ID, update group and fingerprint, roadmap, decisions, plans), and a
`release` skill with the shipping steps. Several later sessions built and published features from these
files alone.
