# Expo Android — verification

> **Status:** proven · **Last verified:** 2026-10-09, Expo SDK 57 · **Proven in:** reading-tracker

All of this ran in Claude cloud sessions except the device checklist.

## Every change

```bash
npm test            # node --test "src/**/*.test.ts" — pure logic, no React Native
npx tsc --noEmit
npx expo lint       # needs eslint.config.js in place (see new-project.md), else it tries to go online
```

The same three run on GitHub for every push (`templates/github/workflows/checks.yml`, Node 22). OTA
updates are only published from a commit whose run passed.

`node --test` works on `.ts` files directly through Node's type stripping (Node ≥ 22.18). Keep tested code
free of enums, namespaces and parameter properties, which stripping doesn't support, and import siblings
with `.ts` extensions.

## Does it bundle for Android?

```bash
EXPO_OFFLINE=1 CI=1 npx expo export --platform android --output-dir <scratch>/dist-android
```

Pass: `› android bundles (1): …/entry-….hbc`. This catches import and Metro errors without a device or an
EAS build.

## UI changes: web preview at phone size

```bash
EXPO_OFFLINE=1 CI=1 npx expo export --platform web --clear --output-dir <scratch>/dist
python3 -m http.server 8765 --directory <scratch>/dist &
```

Then a Node script with Playwright (`require('/opt/node-tools/node_modules/playwright')`):

- Viewport 390×844, `deviceScaleFactor: 2`; `locale: 'de-DE'` to test the German default.
- Collect `pageerror` and console errors; the run passes only with none.
- Seed data through `localStorage` (AsyncStorage's web backend), e.g. old-format data to test a migration.
- Accept dialogs with `page.on('dialog', d => d.accept())` (the web confirm helper uses `window.confirm`).
- Navigate by clicking: the simple static server has no SPA fallback, so `/some-route` 404s on reload.
- Take screenshots and look at them. This found a truncated date label and a web-only crash.

Use `--clear` after `app.json` changes: Metro's cache once served the old `version` in the web bundle.

What the web preview **can't** show: the native date picker (web gets a text field), Android insets (the
web reports 0), the share sheet, the folder picker and OTA status (`expo-updates` is disabled on web).

## Before any OTA publish

```bash
.claude/scripts/fingerprint.sh     # must equal the installed APK's runtime version
```

The publish workflow re-checks this on Expo's servers (`get_build` by fingerprint) and refuses otherwise.

## On the phone (the user)

Give the user an explicit checklist per release, for example: data still there after installing over the
old APK; bottom buttons clear of the navigation bar; native pickers; share sheet and file import; whether
a picked folder still works after closing and reopening the app. For OTA: Settings → "App & updates" says
it runs an update from today, after closing and reopening once or twice.
