# Spec-driven increments

> **Status:** proven · **Last updated:** 2026-11-01 · **Proven in:** cosmic-capitalist (increments 01–05b, empty repository to first finishable playable)

A way to build something larger than one session holds: write the plan as numbered
briefs, and give each brief to one Claude session. It is not tied to a stack.

## The documents

```
docs/concept.md               the pitch, written first
docs/spec/00-OVERVIEW.md      what the MVP must prove, scope in/out, the increment table
docs/spec/CONVENTIONS.md      rules every session follows ("follow CONVENTIONS.md")
docs/spec/NN-<name>.md        one self-contained brief per increment = one session
docs/engine-notes.md          what the code actually is, where it differs from the spec
docs/playtest-NN.md           findings from playing, newest last
docs/design-questions.md      questions play raised, and what was decided
```

## What made it work

- **The overview states a falsifiable claim** the MVP exists to test. Every
  increment serves it, and "out of scope, deliberately" is written down.
- **The increment table has a "playable after?" column.** Early increments were
  model-only with headless tests; one increment turned the pile into a game.
- **CONVENTIONS.md opens with assumptions to verify in session 01.** The first
  session checks them against the real repository and writes the differences to
  `engine-notes.md`. Later sessions read both.
- **A vertical-slice checkpoint:** after the first playable increment, stop and play
  before writing more systems.
- **Increments get inserted when play finds faults.** `05b` didn't exist in the
  original plan; playtesting 05 showed a quarter couldn't be finished, so 05b was
  written before going on.
- **Tag before tuning** (`playable-01`) so there is always a way back.
- **Scripted playtests** (headless bots) answer volume questions a single human run
  cannot, and their findings go into `playtest-NN.md`.

## Prompting a session

"Implement `docs/spec/03-lane-graph-and-gates.md`. Follow `docs/spec/CONVENTIONS.md`.
Read `docs/engine-notes.md` first. Leave the test suite green."
