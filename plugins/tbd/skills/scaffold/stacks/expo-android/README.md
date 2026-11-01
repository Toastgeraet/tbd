# Expo Android app, built in the cloud

> **Status:** proven (scaffold, cloud development, EAS builds, OTA updates from the cloud) · researched (Play Store, iOS) · **Last verified:** 2026-10-09, Expo SDK 57.0.26, React Native 0.86.3 · **Proven in:** reading-tracker

A TypeScript Android app with Expo and Expo Router, developed almost entirely in Claude cloud sessions.
Native builds run on Expo's servers (EAS Build), JS-only changes reach installed phones as over-the-air
updates (EAS Update) published from the cloud session, and the user installs a sideloaded APK.

| Area | Status | File |
| --- | --- | --- |
| New project, step by step | **proven** | [new-project.md](new-project.md) |
| Builds (APK), OTA updates, delivery to phones | **proven** · Play Store **researched** | [build-and-deliver.md](build-and-deliver.md) |
| Verification: tests, web preview, fingerprint, device | **proven** | [verification.md](verification.md) |
| Claude cloud vs local vs phone | **proven** | [cloud.md](cloud.md) |
| All pitfalls (symptom → cause → fix) | **proven** | [pitfalls.md](pitfalls.md) |
| Templates | **proven**, copied from reading-tracker | [templates/](templates/) |

## Choose it when

- The target is an **Android phone app** for the user and friends, maybe the Play Store later.
- The user wants to **work from the phone**: a cloud session edits, tests and ships, and nothing runs on a PC.
- The app is UI plus local data (forms, lists, dates, files), within what Expo's modules cover.

Be careful when:

- **iOS** is needed. Nothing here ran on iOS, and it needs an Apple developer account ($99/year).
- The app needs **native code Expo doesn't ship**. Every native library added later means a new APK and a
  new install on every phone; only JS changes go over the air.
- **Accounts or sync** are needed. Not tried; everything proven here is local-only.

## Versions and environment

| Tool | Version | Where | Notes |
| --- | --- | --- | --- |
| Expo SDK | 57 (`expo ~57.0.26`) | project | `create-expo-app@latest` blank-typescript |
| React Native / React | 0.86.3 / 19.2.3 | project | pinned by `expo install` |
| TypeScript | ~6.0.3 (strict) | project | `types` defaults to `[]` in TS 6, see pitfalls |
| Expo Router | ~57.0.24 | project | routes in `src/app/` |
| Node / npm | 22.22.0 / 10.9.4 | Claude cloud container | Node ≥ 22.18 needed for `node --test` on `.ts` files |
| EAS CLI | `npx eas-cli@latest` (24.11 at the time) | Tobi's PC only | can't log in from a cloud session |
| Playwright / Chromium | 1.56.1, `/opt/node-tools/node_modules/playwright`, `/opt/pw-browsers` | Claude cloud container | preinstalled, for web-preview screenshots |
| Expo connector (MCP) | `mcp__Expo__*` | claude.ai connector | builds, workflows, docs; no token in the session |
| Git Bash | — | Tobi's PC (Windows) | repo once at `C:\Users\Tobi\Workspace\reading-tracker` |

```bash
node -v && npm -v                                   # cloud: 22.22.0 / 10.9.4
npm view expo dist-tags                              # which SDK is "latest"
npx expo-updates fingerprint:generate --platform android | tail -c 200   # runtime fingerprint works
```

## Questions to ask

- **Expo account:** personal or organization? The project lives there (`owner` in `app.json`), and the
  Expo GitHub app has to be able to see the GitHub repo. The user creates and links the project on
  expo.dev; a cloud session can't.
- **Android package name** (e.g. `de.<name>.<app>`). It can never change once phones have the app.
- **Who uses it:** only the user, friends (same APK link), or the Play Store later?
- **Languages?** reading-tracker used a typed dictionary for EN/DE and no i18n library.
- **Will data ever change shape?** If so, version it from day one (see [new-project.md](new-project.md#versioned-data-from-day-one)).

## New project — short version

Full steps with exact commands in [new-project.md](new-project.md).

1. `npx create-expo-app@latest <name> --template blank-typescript --no-install`, then `npm install`.
2. Add Expo Router and the other modules with `EXPO_OFFLINE=1 npx expo install …` (the cloud proxy blocks
   `api.expo.dev`).
3. Set `main: expo-router/entry`, move screens to `src/app/`, set identity and `scheme` in `app.json`.
4. Add the ESLint config, `node --test` setup and the templates (`.gitattributes`, `eas.json`, workflows,
   SessionStart hook, fingerprint script).
5. Install **`expo-updates` before the first APK**, with `runtimeVersion.policy: fingerprint`.
6. User: create the EAS project, link the GitHub repo on expo.dev, run the **first build locally** so EAS
   creates the signing key.
7. From then on, the cloud session builds with the Expo connector and publishes OTA updates through the
   EAS workflow.

## Verify

Summary of [verification.md](verification.md): `npm test` (pure logic via `node --test`),
`npx tsc --noEmit`, `npx expo lint`, an Android bundle via `expo export`, and a web export driven by
Playwright at 390×844 for every UI change. Before any OTA, the runtime fingerprint must equal the
installed APK's. What only a phone can show (native pickers, insets, share sheet, folder access) goes
into an explicit checklist for the user.

## Build and deliver

Summary of [build-and-deliver.md](build-and-deliver.md):

- **APK:** EAS Build, `preview` profile (`buildType: apk`), started from the cloud with the connector's
  `build_run` on a pushed branch. The user opens the link on the phone and installs **over** the old app.
- **OTA:** EAS Update, channel `preview`, published by the `publish-update.yml` EAS workflow, which only
  publishes if an APK with the same fingerprint exists. A GitHub Actions run gates it (tests, types, lint).
- **Decide by fingerprint,** never by guessing: same hash → OTA, different hash → new APK.

## Claude cloud sessions

Everything except creating the EAS project, linking GitHub and the first (keystore-creating) build ran in
cloud sessions. Details, network facts and the handoff docs pattern: [cloud.md](cloud.md).

## Pitfalls that cost the most time

All of them, with exact error text: [pitfalls.md](pitfalls.md).

1. **OTA published but never arrives** — the update's runtime version differs from the APK's. CRLF
   checkouts on Windows, or editing a fingerprinted file (`app.json` incl. `version`, `eas.json`,
   `package.json` scripts, `.gitignore`, icons). Force LF with `.gitattributes`; check the fingerprint
   before publishing.
2. **`npx expo install` / `expo lint` fail with `HTTP Proxy Network Error: Forbidden`** in the cloud —
   `api.expo.dev` is blocked. Prefix with `EXPO_OFFLINE=1`.
3. **Connector `build_run`: `No repository found for appId`** — the GitHub repo isn't linked to the EAS
   project. The user links it on expo.dev (project → GitHub).
4. **First APK without `expo-updates`** can never receive OTA updates; every fix needs a reinstall.
5. **Bottom buttons hidden behind Android's navigation bar** — Expo draws edge-to-edge. Pad scroll
   content by `useSafeAreaInsets().bottom`.

## Files in this stack

| File | Contents | Status |
| --- | --- | --- |
| `README.md` | this map | proven |
| `new-project.md` | setup steps in order, project conventions | proven |
| `build-and-deliver.md` | EAS project, APK builds, OTA updates, fingerprint, delivery | proven · Play Store researched |
| `verification.md` | checks, web preview, fingerprint, device checklist | proven |
| `cloud.md` | what ran in the cloud, locally, on the phone | proven |
| `pitfalls.md` | every pitfall, symptom → cause → fix | proven |
| `templates/` | files reusable as-is (see [new-project.md](new-project.md#4-templates)) | proven |
