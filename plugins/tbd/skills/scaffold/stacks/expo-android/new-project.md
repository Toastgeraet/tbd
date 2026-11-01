# Expo Android — new project

> **Status:** proven · **Last verified:** 2026-10-09, Expo SDK 57.0.26 · **Proven in:** reading-tracker

The steps in the order that worked in reading-tracker, run in a Claude cloud session unless marked
**(user)**. Replace `__PROJECT_NAME__`, `<package>` (e.g. `de.example.myapp`) and `<owner>` (Expo account).

## 1. Scaffold

```bash
npm view expo dist-tags                       # check the current SDK ("latest" was sdk-57)
npx -y create-expo-app@latest __PROJECT_NAME__ --template blank-typescript --no-install
cd __PROJECT_NAME__ && npm install
rm -f App.tsx index.ts                        # Expo Router replaces them
```

The SDK 57 template already ships `AGENTS.md` (Expo's instructions for coding agents: "Expo has changed —
do not trust your training data", routes in `src/app/`) and `.claude/settings.json` enabling the
`expo@claude-plugins-official` plugin. Keep both. reading-tracker scaffolded into a scratch folder and
copied the files into an existing repo; that works too.

## 2. Modules

In a cloud session `npx expo install` needs `EXPO_OFFLINE=1`; the proxy blocks `api.expo.dev`. Offline mode
still pins SDK-compatible versions from the `expo` package's bundled list.

```bash
EXPO_OFFLINE=1 npx expo install expo-router expo-linking expo-constants \
  react-native-safe-area-context react-native-screens
# Web preview deps; installing them also prevents an ERESOLVE on react-dom later (see pitfalls)
EXPO_OFFLINE=1 npx expo install react-dom react-native-web
# What reading-tracker needed besides that (each adds native code, so decide before the first APK):
EXPO_OFFLINE=1 npx expo install @react-native-async-storage/async-storage expo-localization \
  @react-native-community/datetimepicker expo-file-system expo-sharing expo-updates
# Lint and test types
EXPO_OFFLINE=1 npx expo install -- --save-dev eslint eslint-config-expo
npm i -D @types/node@22
```

`expo install` adds config plugins to `app.json` by itself (here: `expo-router`, `expo-localization`,
the date picker, `expo-sharing`). `expo-sharing`'s plugin only adds "share into the app" when enabled, so
it is harmless.

**Install `expo-updates` before the first APK.** reading-tracker's 1.0.0 shipped without it, so that APK
could never receive an over-the-air fix.

## 3. Config files

`package.json` — entry point and scripts:

```json
"main": "expo-router/entry",
"scripts": {
  "start": "expo start", "android": "expo start --android", "web": "expo start --web",
  "test": "node --test \"src/**/*.test.ts\"", "typecheck": "tsc --noEmit", "lint": "expo lint"
}
```

`tsconfig.json`:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "allowImportingTsExtensions": true,
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"]
}
```

`allowImportingTsExtensions` lets pure-logic files import each other as `./dates.ts`, which `node --test`
needs (Node's type stripping doesn't resolve extensionless imports). The Expo base config sets
`noEmit`, which that option requires.

`app.json` — what was set on top of the template:

```json
{
  "expo": {
    "name": "<Display Name>", "slug": "__PROJECT_NAME__", "version": "1.0.0",
    "scheme": "__PROJECT_NAME__", "userInterfaceStyle": "automatic",
    "android": { "package": "<package>" },
    "ios": { "bundleIdentifier": "<package>" },
    "experiments": { "typedRoutes": true },
    "runtimeVersion": { "policy": "fingerprint" },
    "updates": { "url": "https://u.expo.dev/<projectId>" },
    "owner": "<owner>",
    "extra": { "eas": { "projectId": "<projectId>" } }
  }
}
```

`owner` and `extra.eas.projectId` come from the EAS project (step 6); the user's `eas init` or the
expo.dev dashboard writes them. **The package name, owner and projectId must never change** once a phone
has the app: a different package is a different app, and the data stays behind in the old one.

## 4. Templates

Copy from [templates/](templates/) and rename. Dot-folders are stored without the dot so they can't act
on this repository:

| Template | Goes to | What it does |
| --- | --- | --- |
| `gitattributes.txt` | `.gitattributes` | LF everywhere. **Required**: CRLF changes the OTA fingerprint |
| `eas.json` | `eas.json` | `preview` = APK, internal distribution, channel `preview`, remote auto-incremented versionCode, `image: latest` (needed for builds started from GitHub) |
| `eas/workflows/publish-update.yml` | `.eas/workflows/publish-update.yml` | OTA publish from Expo's servers, only if an APK with the same fingerprint exists |
| `github/workflows/checks.yml` | `.github/workflows/checks.yml` | tests, typecheck, lint on every push; gate before publishing |
| `claude/settings.json` | `.claude/settings.json` | Expo plugin + SessionStart hook running `npm ci` in cloud sessions |
| `claude/scripts/fingerprint.sh` | `.claude/scripts/fingerprint.sh` | prints the Android runtime fingerprint (`--sources` lists inputs) |
| `eslint.config.js` | `eslint.config.js` | flat config from `eslint-config-expo` (what `expo lint` would generate online) |
| `src/lib/confirm.ts` | same | `confirmDestructive` / `showMessage`: `Alert` on Android, `window.confirm` on web |
| `src/hooks/useAppUpdates.ts` | same | OTA status + "check" / "restart" actions for a settings screen and a "restart to update" banner |

`chmod +x .claude/scripts/fingerprint.sh` after copying.

## 5. Project conventions that paid off

- **Pure logic in `src/lib/`** with no React Native imports, tested by `node --test` (no Jest).
  Test files start with `/// <reference types="node" />` (TS 6 no longer includes Node types by default).
- **Every scrolling screen pads its bottom** by `spacing + useSafeAreaInsets().bottom`. Expo apps draw
  edge-to-edge, so the last button otherwise sits under the navigation bar. Expo Router already provides
  the `SafeAreaProvider`.
- **Strings in a typed dictionary** (`strings.ts` with `en` and `de: Strings`), so a missing translation is
  a type error. Plurals and parameters as small functions. Default from `expo-localization`'s
  `useLocales()`, with an in-app override.
- **Web-safe dialogs:** `Alert.alert` does nothing in the web preview; use `src/lib/confirm.ts`.
- **Navigation:** `router.push(...)` from a `Pressable` when the pressable has a style array (see pitfalls).
- **Dates as `YYYY-MM-DD` strings** with UTC-based day differences, which avoids DST off-by-one errors.

### Versioned data from day one

reading-tracker stored a bare JSON array in 1.0.0 and had to retrofit versioning in 1.1.0. Start with an
envelope `{ format, schemaVersion, ... }`, one `readDocument(raw)` that migrates step by step and validates,
and use the same function for stored data, JSON backups and CSV imports. Keep the raw data before a
migration, and refuse (don't overwrite) data from a newer schema. With OTA updates a schema bump is
**one-way per phone**: after it, an update from an older commit shows "saved by a newer version", which
is why reading-tracker publishes only from `main`.

## 6. Hand over to EAS (user)

The user, on their PC or on expo.dev:

1. Create the project on expo.dev (or `npx eas-cli@latest init` in the repo), commit the resulting
   `owner` / `projectId` in `app.json`, and push.
2. On expo.dev, project → **GitHub**: install the Expo GitHub app and link the repository. Without it the
   connector's `build_run` fails (see pitfalls).
3. Run the first build locally once: `npx eas-cli@latest build -p android --profile preview`. It asks
   "Generate a new Android Keystore?" — yes. EAS stores the keystore on the Expo account; every later
   build reuses it.

Then continue with [build-and-deliver.md](build-and-deliver.md).

## 7. Docs for future sessions

reading-tracker kept `CLAUDE.md` short (rules that must not break, commands, cloud gotchas) and put detail
in `.claude/docs/` (`architecture.md`, `releases.md` with every build and update, `roadmap.md`,
`decisions.md`, `plans/`), plus a `.claude/skills/release/` skill with the shipping steps. Later sessions
picked up from those files without re-asking settled questions.
