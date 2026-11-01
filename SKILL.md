---
name: scaffold
description: Start a new software project from tech stacks that have already been tried and proven, instead of rediscovering the setup every time. Use when the user wants to create, start, scaffold, bootstrap or set up a new project - a mobile/Android app, a Godot game, an app and game combined, a web project, a backend service, or anything else - or asks which stack to use for something new. Also use when the user wants to record what a project taught about its stack, or to add or update a stack in this skill.
---

# Scaffold

A living library of stacks that have actually been built with, plus the procedure
for starting a new project from one. It is only worth anything while it stays
true, so every session that learns something about a stack writes it back (step 6).

This skill's directory is a git repository. Edits to it are commits there — see
[CONTRIBUTING.md](CONTRIBUTING.md).

## Stack index

| id | Builds | Status | Start here |
| --- | --- | --- | --- |
| `godot` | 2D and UI-heavy games: desktop, web; Android and cloud builds researched | **proven** (desktop, web, headless tests) | [stacks/godot/README.md](stacks/godot/README.md) |
| `expo-android` | Android app with Expo, built mostly in the cloud | **not yet written up** — proven in the user's reading tracker project | — |

Statuses (defined in [CONTRIBUTING.md](CONTRIBUTING.md#status-labels)):

- **proven** — done end-to-end in a real project.
- **verified** — exercised in a throwaway test only.
- **researched** — believed true but never run here.

Never present researched information as proven. Say which one it is when you rely on it.

## Workflow

### 1. Ask what to build

Use `AskUserQuestion` with `multiSelect: true` — picking several means a combination:

- **What do you want to build?** — `Mobile app (Android)`, `Godot game`, `Web project`,
  `Backend service`. "Other" covers everything else (CLI tool, library, desktop app…).

If the tool is unavailable, ask in plain text. Then ask only what you cannot infer:

- Project name, and where it should live (see [workflow preferences](reference/workflow-preferences.md)).
- Git and GitHub: just local, or a GitHub repo too, and private or public.
- Will Claude cloud sessions work on it? This changes the build setup — see
  [reference/claude-cloud.md](reference/claude-cloud.md).
- Anything listed under **Questions to ask** in the matching stack's README.

### 2. Match stacks

- **A proven stack matches** — read its README and follow it. Prefer its templates
  over writing files from memory; they are what actually worked.
- **A combination** — read every stack involved, then settle the integration with
  the user (see [Combinations](#combinations)).
- **No stack matches** — say so plainly. Propose a stack with reasons and let the
  user choose. Treat everything you then do as researched, and offer at the end to
  record it as a new stack.
- **A stack is "not yet written up"** — tell the user which project proved it. Offer
  to start from general knowledge, or wait until that project's session has
  written it up.

### 3. Scaffold

Follow the stack's new-project steps. Templates use `__PROJECT_NAME__` as a
placeholder, and dotfiles ship as `gitignore.txt` and the like, so they don't act on
this repository. Rename them when copying.

### 4. Verify

Run the stack's verification. A scaffold is not done until it runs, its tests
pass, and any build the user asked for has been produced. Report failures with
their output.

### 5. Hand over

Keep it short: what exists, how to run it, which parts are only researched, and
sensible next steps. Make the initial commit only if the user agreed to it in step 1.

### 6. Write back what you learned

At the end of a scaffold, and whenever a session in *any* project hits something
non-obvious about a stack, update the stack docs following
[CONTRIBUTING.md](CONTRIBUTING.md). Ask the user before editing, commit in this
skill's repository, and push only when asked.

What is worth writing back: anything that cost time, contradicted an assumption,
or would have changed a decision. Not generic tutorial material.

## Combinations

**App + game** — nothing here is proven yet. The options, roughly cheapest first:

1. **Godot only.** Godot's `Control` nodes can build app-style screens. One codebase
   and one store listing, but no native look.
2. **Separate app and game sharing a backend service.** Each is built on its own
   proven stack; accounts and data are shared through the service.
3. **A native or Expo app embedding Godot** ("Godot as a library" on Android, Godot
   4.2+). Researched only; expect real integration work.

Ask what forces the decision: one store listing? native UI? shared accounts? Then
recommend one, and record the outcome as a stack once it works.

## Shared references

- [reference/workflow-preferences.md](reference/workflow-preferences.md) — how the user works. Read before step 3.
- [reference/claude-cloud.md](reference/claude-cloud.md) — what a Claude cloud session can and cannot do, across stacks.
- [reference/spec-driven-increments.md](reference/spec-driven-increments.md) — the spec-and-increments process that carried a real game from empty repo to first playable.
