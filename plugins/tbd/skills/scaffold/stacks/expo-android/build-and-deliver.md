# Expo Android — build and deliver

> **Status:** proven (EAS project, APK builds, OTA from a PC and from the cloud) · researched (Play Store, iOS, Android Auto Backup) · **Last verified:** 2026-10-09, Expo SDK 57 · **Proven in:** reading-tracker

## The pieces

| Piece | What it is | Where it lives |
| --- | --- | --- |
| EAS project | the app's record on expo.dev: builds, updates, credentials, GitHub link | Expo account (reading-tracker: an Expo organization) |
| Signing key | Android keystore. Every APK must be signed with the same key or it won't install over the old one | **EAS remote credentials** on the Expo account, created by the first local build. Never in git |
| GitHub link | lets EAS pull the repo for builds and workflows started from the connector | expo.dev → project → GitHub (Expo GitHub app) |
| Expo token | — | **none needed**: the cloud session uses the Expo connector, workflows run on Expo's side |
| `preview` profile | APK, internal distribution, channel `preview` | `eas.json` |
| versionCode | auto-incremented by EAS (`appVersionSource: remote`) | EAS |

## OTA update or new APK: decide by fingerprint

`runtimeVersion.policy: fingerprint` makes the runtime version a hash of everything native. An APK only
accepts updates with exactly its own hash.

```bash
.claude/scripts/fingerprint.sh            # current hash
.claude/scripts/fingerprint.sh --sources  # what it covers
```

Same hash as the installed APK → OTA. Different → new APK. Measured in reading-tracker (SDK 57, Android),
the hash covered: `app.json` (the resolved config, **including `version`** — bumping 1.1.0 → 1.1.1 changed
it), `eas.json`, `package.json` `scripts`, `.gitignore`, the icon files, config-plugin sources and the
autolinked native modules in `node_modules`. `eas.json` and `.gitignore` are hashed **byte for byte**, so
line endings matter; `app.json` and `package.json` are parsed as JSON, so theirs don't.

So for an OTA release, don't touch `app.json` (not even `version`), `eas.json`, `package.json` scripts,
`.gitignore` or icons. `.eas/`, `.github/`, `.claude/`, `.gitattributes`, docs and tests are not covered.

Record every APK's fingerprint. EAS's `runtimeVersion` in `build_info` matched the locally computed hash
exactly, so the local check is reliable (on LF checkouts).

## APK builds

**First build: on the user's PC** (`npx eas-cli@latest build -p android --profile preview`), because it
creates the keystore interactively. About 30 minutes including the queue.

**Later builds: from the cloud session** with the Expo connector:

```text
mcp__Expo__build_run   appId=<projectId>  platform=ANDROID  buildProfile=preview  gitRef=<pushed branch>
mcp__Expo__build_info  buildId=…   → status, appVersion, appBuildVersion, runtimeVersion, artifacts.buildUrl
mcp__Expo__build_logs  buildId=…   → after it finished or errored
```

- Requires the GitHub link and `image` set on the profile (`"android": { "image": "latest" }`).
- **Free-tier queue times vary a lot:** about 13 minutes for the first build, about 110 minutes for the
  second. A queued build shows `IN_QUEUE` with an unchanged `updatedAt` and `appVersion: null` the whole
  time. That's normal; it started by itself, and building then took about 20 minutes.
- Don't poll: schedule a check-in (`send_later`, 20–30 minutes) and report when it changes.
- Fallback if the user won't wait: cancel on expo.dev and build locally.

**Bump `version` in `app.json` for every APK** (it's the user-visible version). versionCode increments by
itself.

**Delivery:** the user opens `artifacts.buildUrl` on the phone and installs. Android asks once to allow
installs from the browser. **Install over the old app; uninstalling deletes its data.** Friends get the
same link. EAS artifact links expire after about 14 days; the build page on expo.dev remains.

## OTA updates

Set up in the first APK: `expo-updates`, `runtimeVersion.policy: fingerprint`,
`updates.url: https://u.expo.dev/<projectId>`, `channel: preview` on the build profile.

Default behaviour (proven): on each start the app checks for an update and downloads it in the background,
then uses it on the **next** start. Users need "close the app completely (swipe it away) and reopen, maybe
twice". reading-tracker added an in-app status (`templates/src/hooks/useAppUpdates.ts`): a Settings
section with version, "running the built-in code / an update from <date>", "Check for updates" with
download progress, "Restart now", and a list banner "update ready, tap to restart". It shipped as an OTA
itself because `expo-updates` was already in the APK.

### Publishing from the cloud (default since 2026-10-07)

`templates/eas/workflows/publish-update.yml`, started with the connector:

```text
mcp__Expo__workflow_run   appId=<projectId>  fileName=publish-update.yml  gitRef=main
mcp__Expo__workflow_info  …  → jobs, gitCommitHash, outputs (first_update_group_id)
mcp__Expo__workflow_logs  …  → on failure
```

Jobs: `fingerprint` (Android hash, `environment: preview`) → `get_build` (a `preview` APK with exactly that
hash) → `publish` (`type: update`, channel `preview`, Android only), or `needs_new_apk`, which fails the run
and publishes nothing. No `on:` trigger, so pushes never publish by themselves. The update message is the
latest commit message of the ref.

Observed: about 2 minutes end to end with no queue; once about 3.5 hours waiting in the free queue.
Fingerprints computed on Expo's Linux servers aren't affected by the user's checkout (line endings).

reading-tracker's rules around it: ask the user before every publish; publish only from `main` (an update
from a side branch is undone by the next `main` update, and after a schema bump locks phones out of their
data); wait for the GitHub **Checks** run on that commit to pass first (`templates/github/workflows/checks.yml`;
runs on GitHub, outside the EAS queue).

### Publishing from a PC (fallback)

```bash
git pull
npx expo-updates fingerprint:generate --platform android   # "hash" must equal the APK's fingerprint
npx eas-cli@latest update --channel preview --platform android --message "<what changed>" \
  --environment preview --clear-cache
```

Check the printed runtime version. If it differs from the APK's, nothing will ever download it (see
pitfalls: CRLF). `--platform android` avoids a useless iOS update group.

### Cost (free plan)

Measured after the first cloud publish: 992.69 KiB of the free 100 GiB monthly update bandwidth. Bandwidth
counts phones downloading updates, not workflows. The Android JS bundle was about 2.9 MB, about 1.2 MB
compressed, so roughly 1 MB per phone per update. Updates are free for up to 1,000 monthly active users
(Expo billing FAQ, **researched**). Workflow-run cost on the free plan wasn't documented clearly; nothing
was billed.

## Researched, not run

- **Play Store:** `production` profile builds an AAB (in `eas.json`, never built). Let Google use the
  existing EAS key (Play App Signing with the uploaded key) so sideloaded users can upgrade in place.
  Needs a privacy policy and store listing.
- **iOS:** needs an Apple developer account; `ios.bundleIdentifier` is set but nothing was built.
- **Android Auto Backup:** Expo's default `allowBackup: true` lets Android back app data up to Google
  Drive. Not relied on, and restore for sideloaded installs is unverified.
