# Claude cloud sessions — what they can and cannot do

> **Status:** researched, except where marked · **Last checked:** 2026-11-01

Stack-independent facts about developing in a Claude cloud session connected to
GitHub. The user has **proven** a mostly-cloud workflow with Expo (the reading
tracker); when that stack is written up, its session should correct and extend
this page with what it actually observed.

## The environment

- A Linux container managed by Anthropic, with the GitHub repository cloned into
  it. The session can commit, push branches and open pull requests.
- **Ephemeral.** Each new session starts clean, so toolchains installed in one are
  gone in the next unless the environment's setup script installs them or a cache
  survives. Measure what that costs per session before relying on it.
- **Network access is configurable** and may be limited to an allowlist. Large
  downloads from tool vendors (SDKs, engine templates) may need broader access.
- **CPU only.** No GPU, so anything that renders needs software rendering, and
  is slow.
- **No hardware virtualisation** (as far as known), so Android emulators are out.
  Testing on a real device stays with the user.

## The pattern that works

Keep the session light; send heavy native builds elsewhere; deliver the artefact
to the user's device.

| Stack | Session does | Heavy build runs on | Delivery |
| --- | --- | --- | --- |
| Expo (proven, not yet written up) | edit, test, push | Expo EAS (presumably — confirm) | install link on the phone |
| Godot (researched) | edit, headless import + tests, push | GitHub Actions | APK artifact or release |

## Using this skill in a cloud session

This skill ships in the `tbd` plugin. Plugins installed for the user on their PC
are **not** present in a cloud session. The documented way to give one repository
the plugin is to register the marketplace at project scope and commit the result:

```bash
claude plugin marketplace add Toastgeraet/claude-tbd --scope project   # writes .claude/settings.json
```

Untested: whether a cloud session can clone the *private* `claude-tbd` repository
that way. It clones with whatever git credentials the session has. Record here what
actually works.

## Before relying on the cloud for a new stack, find out

1. Which toolchain downloads it needs, their size, and whether the network
   access level allows them.
2. Whether tests can run headless on CPU.
3. What has to build elsewhere, and how the artefact reaches the user.
4. Which secrets the build needs, and where they live (repository secrets,
   build-service tokens). Never in git.
