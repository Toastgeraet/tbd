# Godot — Claude cloud sessions and CI builds

> **Status:** proven (editing, import, tests, probes, screenshots in a cloud session) · researched (APK builds in the cloud or CI) · **Last checked:** 2026-11-01 · **Proven in:** rechen-trainer (built from an empty repo in a cloud session; the APK was exported on the PC)

How a Godot project is developed in a Claude cloud session connected to GitHub,
and how it could be built without the user's PC. General cloud
facts are in [../../reference/claude-cloud.md](../../reference/claude-cloud.md).

## What a cloud session can do

A cloud session is a Linux container with the repository cloned. The official
Linux Godot build runs there; use `--headless` throughout.

| Task | Works? | Notes |
| --- | --- | --- |
| Getting Godot | **proven** | `curl -sSL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` (78 MB) went through the proxy. Unzip into the scratchpad, not the repo. |
| Editing GDScript, scenes, shaders | **proven** | Plain text files. Hand-written `.tscn` (format=3, no `uid`) imported fine. |
| Import, error checks, test suite | **proven** | The commands in [verification.md](verification.md), with the Linux binary. A fresh clone has no `.godot/`, so `--import` must run first. |
| Web export | Yes | Needs the export templates in the container. |
| Android APK export | *researched* | Needs JDK 17, the Android SDK and templates. Headless Android exports on Linux are a well-trodden CI path. |
| Screenshots | **proven** | `xvfb-run` was preinstalled; GL Compatibility rendered correctly in software. Command in [verification.md](verification.md#screenshots-on-linux-without-a-display). |
| Physics tuning probes | **proven** | Headless with `--fixed-fps 60` runs faster than real time. |
| Running on a device or emulator | No | The emulator needs hardware virtualisation (KVM), which containers usually lack. Testing on a phone stays with the user. |

**Downloads are the practical problem.** The template bundle alone is about
1.2 GB. Each new session repeats it unless the environment caches it, and the
session's network access level may need to allow the Godot and Google download
hosts.

## Recommended split

**proven, the simplest route (rechen-trainer):** the session does everything up to
a pushed commit, and the user exports on the PC from the editor (Remote Deploy to
the phone, or *Export Project…* for an APK file). The handover is the step list
in [android-export.md](android-export.md). No CI needed.

**researched, the route without the PC:**

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
- Tool paths in the README's environment table are for Windows. In the cloud
  container (2026-11-01): Java 21 (OpenJDK) preinstalled, no Android SDK. `gh
  auth status` claimed an invalid token, but `gh api` (REST) worked.
- **Tags can't be pushed** from the session (HTTP 403 from the git proxy;
  branches push fine). Release tags are made on the PC or on GitHub's release
  page. See [claude-cloud.md](../../reference/claude-cloud.md).
- `.uid` files must be committed; the templates and the editor both rely on them.
