#!/usr/bin/env bash
# Update the scaffold skill to the latest version from its remote.
#
#   ~/.claude/skills/scaffold/scripts/update.sh
#
# Never discards anything: stops on uncommitted edits or a diverged history, and
# warns about local commits that have not been pushed yet.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
expected="$HOME/.claude/skills/scaffold"

if [ "$(cd "$expected" 2>/dev/null && pwd)" != "$repo" ]; then
	echo "Note: this copy is at $repo, but Claude Code only loads it from $expected."
fi

if [ -z "$(git -C "$repo" remote)" ]; then
	echo "No remote configured yet - nothing to update from."
	exit 0
fi

git -C "$repo" fetch --quiet || { echo "git fetch failed."; exit 1; }

if [ -n "$(git -C "$repo" status --porcelain)" ]; then
	echo "Uncommitted changes in the skill - commit (and push) or stash them first:"
	git -C "$repo" status --short
	exit 1
fi

if ! counts="$(git -C "$repo" rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null)"; then
	echo "The current branch has no upstream. Set one with: git -C \"$repo\" push -u origin main"
	exit 1
fi
read -r ahead behind <<<"$counts"

if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
	echo "Local and remote have both moved ($ahead ahead, $behind behind). Rebase by hand:"
	echo "  git -C \"$repo\" pull --rebase"
	exit 1
fi
if [ "$ahead" -gt 0 ]; then
	echo "$ahead local commit(s) not pushed - other machines don't have them yet:"
	git -C "$repo" log --oneline '@{u}..HEAD'
fi
if [ "$behind" -eq 0 ]; then
	echo "Already up to date."
	exit 0
fi

before="$(git -C "$repo" rev-parse HEAD)"
git -C "$repo" pull --ff-only --quiet || { echo "git pull failed."; exit 1; }
echo "Updated:"
git -C "$repo" log --oneline "$before..HEAD"
