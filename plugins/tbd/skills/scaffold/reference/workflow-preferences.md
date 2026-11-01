# How the user works

> **Status:** proven — collected from sessions with the user · **Last updated:** 2026-11-01

These apply to every stack. Add to them when the user corrects how a session
works; note the date and the reason.

## Environment

- Windows 11. Claude works through Git Bash and Windows PowerShell 5.1.
- Projects live in `C:\Users\Tobi\Documents\<project>`. Some older experiments
  are in `C:\Users\Tobi\Documents\Workspace\`.
- GitHub account **Toastgeraet**, with SSH remotes (`git@github.com:Toastgeraet/<repo>.git`).
- Uses the Claude desktop app locally, and Claude cloud sessions connected to GitHub.

## Preferences

- **Commit only when asked; push only when asked.** "Commit this" means commit, not
  push. After committing, say whether the branch is ahead of its remote.
- **Don't run long or heavy build steps as routine.** For Godot: "Stop exporting
  the web build every time. I will tell you when I need a web build. Otherwise I
  will just run it from the editor GUI." (2026-09)
- **Large downloads (SDKs, export templates):** offered the choice, the user
  installed Godot's 1.2 GB export templates through the editor GUI rather than
  letting Claude download them. Offer the GUI route first.
- **"Use typical patterns and best practices"** of the stack — idiomatic over clever.
- Wants **verification, not assumption**: run the thing, show screenshots of
  visual work, and say plainly which parts were not checked.
- When asked a question ("is it possible…?"), answer it. Don't start building
  until asked ("not yet" means not yet).
