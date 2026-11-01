# Update the scaffold skill to the latest version from its remote.
#
#   ~\.claude\skills\scaffold\scripts\update.ps1
#
# Never discards anything: stops on uncommitted edits or a diverged history, and
# warns about local commits that have not been pushed yet.

$repo = Split-Path -Parent $PSScriptRoot
$expected = Join-Path $HOME ".claude\skills\scaffold"

if ((Resolve-Path $repo).Path -ne (Resolve-Path $expected -ErrorAction SilentlyContinue).Path) {
    Write-Host "Note: this copy is at $repo, but Claude Code only loads it from $expected." -ForegroundColor Yellow
}

$remote = git -C $repo remote
if (-not $remote) {
    Write-Host "No remote configured yet - nothing to update from."
    exit 0
}

git -C $repo fetch --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "git fetch failed." -ForegroundColor Red; exit 1 }

$dirty = git -C $repo status --porcelain
if ($dirty) {
    Write-Host "Uncommitted changes in the skill - commit (and push) or stash them first:" -ForegroundColor Yellow
    git -C $repo status --short
    exit 1
}

$counts = git -C $repo rev-list --left-right --count "HEAD...@{u}" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "The current branch has no upstream. Set one with: git -C `"$repo`" push -u origin main"
    exit 1
}
$ahead, $behind = $counts -split '\s+' | ForEach-Object { [int]$_ }

if ($ahead -gt 0 -and $behind -gt 0) {
    Write-Host "Local and remote have both moved ($ahead ahead, $behind behind). Rebase by hand:" -ForegroundColor Yellow
    Write-Host "  git -C `"$repo`" pull --rebase"
    exit 1
}
if ($ahead -gt 0) {
    Write-Host "$ahead local commit(s) not pushed - other machines don't have them yet:" -ForegroundColor Yellow
    git -C $repo log --oneline "@{u}..HEAD"
}
if ($behind -eq 0) {
    Write-Host "Already up to date."
    exit 0
}

$before = git -C $repo rev-parse HEAD
git -C $repo pull --ff-only --quiet
if ($LASTEXITCODE -ne 0) { Write-Host "git pull failed." -ForegroundColor Red; exit 1 }
Write-Host "Updated:" -ForegroundColor Green
git -C $repo log --oneline "$before..HEAD"
