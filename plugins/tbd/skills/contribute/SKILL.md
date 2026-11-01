---
name: contribute
description: Look back over the current session for anything worth adding to the tbd plugin's skills - stack setup, pitfalls, environment and cloud facts, workflow preferences - and turn what the user picks into a pull request on the tbd repository. Use when the user asks whether anything from this session should go into tbd, wants to contribute or write back learnings to tbd or the scaffold skill, or asks to record what this session taught.
---

# Contribute

Turns what a session learned into a pull request on the `tbd` plugin's dev repo.
The PR is the review step: nothing reaches `main` — and through auto-update every
machine — until the user merges it.

Running this skill is the user asking for that PR. Pushing a `contribute/…`
branch and opening the PR need no further confirmation beyond step 2. Never push
to `main`, never merge, never force-push.

## 1. Harvest

Go back over this session: the conversation, the commits made in it, and the
files it changed. Collect candidates — things that:

- cost time, failed first, or contradicted an assumption;
- are exact commands, settings or versions that worked;
- are pitfalls, written as **symptom → cause → fix**;
- are environment or Claude cloud facts;
- changed a decision, or are the user correcting how a session works.

For each candidate, decide:

- **Where it goes.** Read the dev repo's skills (step 3 locates it): every
  `plugins/tbd/skills/<skill>/SKILL.md`, and that skill's `CONTRIBUTING.md` when
  it has one. The CONTRIBUTING file is the authority on what belongs where and
  how it is written. Something that fits no skill is a possible new skill —
  list it, but don't build one unless the user picks it.
- **Its status label** — proven, verified or researched, as the target skill's
  CONTRIBUTING defines them. Only what actually ran in this session or its
  project is proven.
- **Whether it is already there.** Check the dev repo's `origin/main` after a
  fetch, not the installed copy, which can lag behind. Also check open PRs
  (`gh pr list --repo Toastgeraet/tbd`) when `gh` works.

Drop anything CONTRIBUTING says to leave out: generic tutorial material, the
project's business logic, and anything private. **The repository is public** —
no secrets, tokens, personal email addresses or private project details.

## 2. Let the user pick

If nothing survives, say so in one line and stop. No branch, no PR.

Otherwise use `AskUserQuestion` with `multiSelect: true`. One option per
candidate: the label is the gist, the description names the target file and the
status label. It takes at most four options per question and four questions;
with more candidates, group related ones. Without the tool, list them and ask.

## 3. Prepare the dev repo

- **Locate it.** On Tobi's PC: `C:\Users\Tobi\Documents\tbd`. Elsewhere, clone
  `git@github.com:Toastgeraet/tbd.git` into a scratch folder. In a Claude cloud
  session, first attach `Toastgeraet/tbd` with push access (`add_repo`), or the
  GitHub proxy won't serve it.
- **Branch from fresh `main`:** `git fetch`, then
  `git switch -c contribute/<topic> origin/main`. If the working tree has
  uncommitted changes, stop and ask — they are not yours.
- **Author email.** Commits must not carry a personal address. If
  `git config user.email` isn't a `noreply` address, set one for this repository
  only: `git config user.email Toastgeraet@users.noreply.github.com`.

## 4. Write

Edit following the target skill's CONTRIBUTING: status lines, *Last verified*
dates, index rows, size limits. Keep each change in the voice and density of the
file around it. When a change corrects something, say so — the old text may
already have misled a session.

A new skill goes in `plugins/tbd/skills/<name>/SKILL.md` and gets a row in the
skills table of the repository `README.md`.

## 5. Check

- Read the whole diff (`git diff origin/main`) for secrets, personal data and
  private project details.
- Validate when the `claude` CLI is available: `claude plugin validate .` and
  `claude plugin validate ./plugins/tbd`. "No version specified" is deliberate;
  plugin-directory warnings (missing icon) don't apply to this marketplace.
  Anything else needs fixing.
- Links inside changed files resolve, including `#anchors` to renamed headings.

## 6. Commit, push, open the PR

Commit messages follow the target skill's convention — for scaffold,
`scaffold/<stack-id>: <what changed>`; otherwise `<skill>: <what changed>`.
Then push the branch: `git push -u origin contribute/<topic>`.

Open the PR against `main`, using the first route that works:

1. `gh pr create --repo Toastgeraet/tbd --base main --head contribute/<topic>`
   — needs `gh auth status` to report a login.
2. **Cloud session:** the GitHub proxy refuses `gh pr` (GraphQL), *researched*.
   Use a GitHub connector tool for creating pull requests if the session has
   one, otherwise REST:
   `gh api repos/Toastgeraet/tbd/pulls -f base=main -f head=contribute/<topic> -f title=… -f body=…`.
3. Otherwise give the user the link that opens the PR form:
   `https://github.com/Toastgeraet/tbd/compare/main...contribute/<topic>?expand=1`.

PR body:

- One bullet per contribution: what it says, the file, the status label.
- Where it came from — the project and what happened, without private detail.
- Anything deliberately left out, and candidates the user declined, in one line.

## 7. Report

The PR link and one line per contribution. Mention that merging ships it to every
machine with auto-update on. If the PR had to fall back to the compare link,
say why (for example `gh` not logged in) and how to fix it next time.
