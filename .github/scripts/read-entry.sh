#!/usr/bin/env bash
# Compute the newly-added registry entry (head - base) and expose it as step outputs.
# Usage: read-entry.sh <registry-file>
# Env:   GITHUB_OUTPUT - set by the runner
# Reads base.json produced by validate-entry.sh.
# Outputs: entry (compact JSON of the new entry), repo (its repo field)
set -euo pipefail

REGISTRY_FILE="$1"

NEW=$(jq -n \
  --slurpfile base base.json \
  --slurpfile head "$REGISTRY_FILE" \
  '($head[0]) - ($base[0]) | .[0]')

{
  echo "entry=$(echo "$NEW" | jq -c .)"
  echo "repo=$(echo "$NEW" | jq -r .repo)"
} >> "$GITHUB_OUTPUT"
