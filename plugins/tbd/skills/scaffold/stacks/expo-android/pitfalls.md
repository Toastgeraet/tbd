# Expo Android — pitfalls

> **Status:** proven — every item happened in reading-tracker (2026-10-06 to 2026-10-09, Expo SDK 57) · **Proven in:** reading-tracker

Symptom → cause → fix.

## OTA updates

- **`eas update` succeeds, but no phone ever gets the update** (the printed Android runtime version is e.g.
  `bfcae3e0…`, the APK's is `a9760e1c…`) — the fingerprint was computed on Windows with CRLF checkouts;
  `eas.json` and `.gitignore` are hashed byte for byte. Nothing warns. Add `.gitattributes`
  (`* text=auto eol=lf`), renormalize the clone once (`git rm --cached -r -q . && git reset --hard`), and
  check `npx expo-updates fingerprint:generate --platform android` before publishing. Publishing from the
  EAS workflow avoids it entirely. The stray update is harmless.
- **A JS-only change suddenly "needs a new APK"** — a fingerprinted file was edited: `app.json` (even just
  `version`), `eas.json`, `package.json` `scripts`, `.gitignore`, icons. Revert it, or batch it into the
  next APK. Don't bump `version` for OTA releases.
- **The first APK can't be fixed over the air** — it was built without `expo-updates`. Only a reinstall
  helps. Add `expo-updates` with the fingerprint policy before the first build.
- **User can't tell whether the update arrived** — by default updates download silently and apply on the
  next start. Tell users "close completely and reopen, maybe twice", and ship an in-app status
  (`templates/src/hooks/useAppUpdates.ts`).
- **`Multiple runtime versions are defined, multiple update groups have been published`** — normal with the
  fingerprint policy (iOS and Android hash differently). Publish with `--platform android` when there's no
  iOS build.
- **Workflow `publish` job fails with `SERVER_ERROR` "Failed to fetch project sources. Re-run the job."** —
  an Expo infrastructure error. Re-run; nothing was published.
- **`workflow_run`'s reply names an older commit** than the one published — the reply line shows the
  workflow file's commit. Trust `gitCommitHash` in `workflow_info`.
- **After a data-schema bump, phones show "saved by a newer version"** — an update from an older commit or
  side branch reached them after the migrating one; schema bumps are one-way per phone. Publish only from
  `main`.

## Builds and delivery

- **Connector `build_run`: `GraphQL error: No repository found for appId …`** — the GitHub repo isn't linked
  to the EAS project (adding `projectId` to `app.json` isn't enough). Link it on expo.dev → project →
  GitHub. Also set `"image": "latest"` on the profile; GitHub-started builds need it.
- **A build sits in `IN_QUEUE` for over an hour, `updatedAt` frozen, `appVersion: null`** — the free-tier
  queue, not a hang (13 minutes once, about 110 minutes another time). Wait, with a scheduled check-in; or
  cancel and build locally if the user is in a hurry.
- **A reinstall lost all data** — uninstalling deletes app data. Always install the new APK **over** the old
  one (same package, same EAS keystore).

## Cloud session tooling

- **`npx expo install …` fails with `Error: HTTP Proxy Network Error: Forbidden`** (after "Unable to fetch
  compatibility data from React Native Directory") — the proxy blocks `api.expo.dev`. Use
  `EXPO_OFFLINE=1 npx expo install …`.
- **`npx expo lint` prints "No ESLint config found. Configuring automatically." and fails with the same
  proxy error** — install `eslint eslint-config-expo` with `EXPO_OFFLINE=1 npx expo install -- --save-dev`
  and add `eslint.config.js` (template) yourself.
- **`npm i -D @types/node@22` fails with `ERESOLVE could not resolve … react-dom@19.3.0 … Found: react@19.2.3`**
  — Expo Router's dependencies want `react-dom` as a peer and npm picked a newer one. Install
  `react-dom react-native-web` with `EXPO_OFFLINE=1 npx expo install` first (pins 19.2.3).
- **`tsc`: `Cannot find name 'node:test'. Do you need to install type definitions for node?` even with
  `@types/node` installed** — TypeScript 6 defaults `types` to `[]`. Add `/// <reference types="node" />` at
  the top of test files.
- **`node --test` can't find imports in `src/lib`** — Node's type stripping doesn't resolve extensionless
  imports. Import as `./dates.ts` and set `allowImportingTsExtensions: true` in `tsconfig.json`.
- **`curl` to docs.expo.dev returns `CONNECT tunnel failed, response 403`** — proxy. Use the Expo
  connector's `read_documentation`.
- **Web export shows an old `version` from `app.json`** — Metro cache. Add `--clear` to `expo export`.

## Web preview (web is only a preview)

- **Delete buttons do nothing in the browser** — `react-native-web`'s `Alert.alert` is an empty function.
  Use `templates/src/lib/confirm.ts` (`window.confirm` on web).
- **Screen crashes on web with `TypeError: Failed to set an indexed property [0] on 'CSSStyleDeclaration'`**
  — `<Link asChild>` around a `Pressable` whose `style` is an array. Use `onPress={() => router.push(…)}`.
- **`expo-updates` reports `isEnabled = true` on web** — its web module says so, but there are no updates
  there. Guard with `Platform.OS !== 'web'` (the template does).

## Android UI

- **The last button on a screen is hidden behind the navigation buttons** — Expo apps draw edge-to-edge.
  Pad scroll content by `useSafeAreaInsets().bottom` (`react-native-safe-area-context`, already in every
  Expo Router app, so it's an OTA fix).
