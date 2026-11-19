#!/usr/bin/env bash
# Validate that a PR adds exactly one entry to the registry and no duplicate ids exist.
# Usage: validate-entry.sh <registry-file> <label>
# Env:   BASE_REF  - base branch of the PR (e.g. main)
# Writes base.json (the base-branch version of the registry) for later steps.
set -euo pipefail

REGISTRY_FILE="$1"   # e.g. community-plugins.json
LABEL="$2"           # e.g. plugin
: "${BASE_REF:?BASE_REF env var is required}"

git show "origin/${BASE_REF}:${REGISTRY_FILE}" > base.json

# check that exactly one entry was added and that none were removed or modified
jq -n \
  --slurpfile base base.json \
  --slurpfile head "$REGISTRY_FILE" \
  '
  ($base[0]) as $b | ($head[0]) as $h |
  ($h | length) == ($b | length) + 1
  and ($b - $h | length) == 0
  ' | grep -q true || {
    echo "::error::PR must add exactly one ${LABEL} and modify no existing ones"
    exit 1
  }

DUP_ID=$(jq -r 'group_by(.id) | map(select(length > 1) | .[0].id) | .[0] // empty' "$REGISTRY_FILE")

if [ -n "$DUP_ID" ]; then
  echo "::error file=${REGISTRY_FILE}::Duplicate ${LABEL} id detected '${DUP_ID}'"
  exit 1
fi
