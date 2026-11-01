# Godot — Claude cloud sessions and CI builds

> **Status:** researched · **Last checked:** 2026-11-01 · **Proven in:** —

How a Godot project could be developed in a Claude cloud session connected to
GitHub, and built without the user's PC. Nothing here has been run. General cloud
facts are in [../../reference/claude-cloud.md](../../reference/claude-cloud.md).

## What a cloud session can do

A cloud session is a Linux container with the repository cloned. The official
Linux Godot build runs there; use `--headless` throughout.

| Task | Works? | Notes |
| --- | --- | --- |
| Editing GDScript, scenes, shaders | Yes | Plain text files. |
| Import, error checks, test suite | Yes | The commands in [verification.md](verification.md), with the Linux binary. A fresh clone has no `.godot/`, so `--import` must run first. |
| Web export | Yes | Needs the export templates in the container. |
| Android APK export | Yes, with setup | Needs JDK 17, the Android SDK and templates. Headless Android exports on Linux are a well-trodden CI path. |
| Screenshots | Probably | No GPU. Godot under a virtual display (Xvfb) with Mesa's software OpenGL (llvmpipe) should render; GL Compatibility is the easiest renderer for it. Unverified. |
| Running on a device or emulator | No | The emulator needs hardware virtualisation (KVM), which containers usually lack. Testing on a phone stays with the user. |

**Downloads are the practical problem.** The template bundle alone is about
1.2 GB. Each new session repeats it unless the environment caches it, and the
session's network access level may need to allow the Godot and Google download
hosts.

## Recommended split

Mirror what Expo does with EAS: keep the heavy native build out of the session.

1. **The cloud session** edits, runs the headless checks and tests, and pushes a
   branch or opens a PR. It needs only the Godot binary (about 60 MB), not the
   templates or the Android toolchain.
2. **GitHub Actions** builds on every push. GitHub's Ubuntu runners come with the
   Android SDK and several JDKs, so the workflow only has to fetch Godot and the
   templates, which `actions/cache` can keep between runs.
3. **The user** downloads the APK from the workflow run or a GitHub Release onto
   the phone.

Builds then happen whether a change came from a cloud session, a local session, or
the user working in the editor.

## Workflow outline (not yet written or run)

1. Check out the repository.
2. Restore the cache for the Godot binary and templates; on a miss, download
   `Godot_v<ver>-stable_linux.x86_64.zip` and
   `Godot_v<ver>-stable_export_templates.tpz` from the `godotengine/godot` GitHub
   releases. Unzip the templates into
   `~/.local/share/godot/export_templates/<ver>.stable/`.
3. Point Godot at the runner's Android SDK and JDK 17. These are editor settings
   (`export/android/android_sdk_path`, `export/android/java_sdk_path`).
4. `--headless --import`, then the test suite — fail the build if tests fail.
5. `--headless --export-debug "Android" build/game.apk`, or `--export-release`
   with a release keystore provided from repository secrets.
6. Upload the APK as an artifact.

The community `godot-ci` Docker image packages steps 2–3 and is worth comparing
against. When this runs for real, replace this outline with the working workflow
file in `templates/` and upgrade the status.

## Project-specific notes

- The `d3d12` rendering-device setting is Windows-only and ignored on Linux.
- Tool paths in the README's environment table are for Windows. Record the Linux
  ones here once known.
- `.uid` files must be committed; the templates and the editor both rely on them.
