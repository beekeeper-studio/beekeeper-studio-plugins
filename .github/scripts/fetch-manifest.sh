#!/usr/bin/env bash
# Fetch the submission's manifest.json and confirm its id matches the registry entry.
# Usage: fetch-manifest.sh
# Env:   ENTRY    - compact JSON of the new registry entry
#        REPO     - owner/repo of the submission
#        GH_TOKEN - token for gh
# Writes manifest.json for later steps.
set -euo pipefail

: "${ENTRY:?ENTRY env var is required}"
: "${REPO:?REPO env var is required}"

# gh api hits the repo's default branch automatically; raw header returns file contents
gh api "repos/${REPO}/contents/manifest.json" \
  -H "Accept: application/vnd.github.raw" > manifest.json \
  || { echo "::error::Could not fetch manifest.json from ${REPO}"; exit 1; }

ERR=$(jq -n \
  --argjson entry "$ENTRY" \
  --slurpfile manifest manifest.json \
  '
  ($manifest[0]) as $m |
  if $entry.id == $m.id then true
  else error("id mismatch: entry=\($entry.id) manifest=\($m.id)")
  end
  ' 2>&1) || { echo "::error::$ERR"; exit 1; }
