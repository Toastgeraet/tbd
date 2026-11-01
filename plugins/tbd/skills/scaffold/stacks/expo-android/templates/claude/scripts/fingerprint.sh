#!/usr/bin/env bash
# Prints the Android runtime fingerprint. Same hash as the installed APK => the change can ship over the air.
# Usage: .claude/scripts/fingerprint.sh            (current working tree)
#        .claude/scripts/fingerprint.sh --sources  (also list which inputs the hash covers)
set -euo pipefail
cd "$(dirname "$0")/../.."
npx expo-updates fingerprint:generate --platform android 2>/dev/null | node -e '
let s = "";
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  const j = JSON.parse(s);
  console.log(j.hash);
  if (process.argv.includes("--sources")) {
    for (const x of j.sources) console.error(`${x.type}\t${(x.reasons || []).join(",")}\t${x.filePath || x.id}`);
  }
});' -- "$@"
