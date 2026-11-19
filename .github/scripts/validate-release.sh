#!/usr/bin/env bash
# Validate the submission's latest release: tag matches the manifest version and the
# required assets (manifest.json + <id>-<version>.zip) are attached.
# Usage: validate-release.sh <label>
# Env:   REPO     - owner/repo of the submission
#        GH_TOKEN - token for gh
# Reads manifest.json produced by fetch-manifest.sh.
set -euo pipefail

LABEL="$1"   # e.g. plugin
: "${REPO:?REPO env var is required}"

gh api "repos/${REPO}/releases/latest" > release.json 2>/dev/null \
  || { echo "::error::No release found on ${REPO}"; exit 1; }

TAG=$(jq -r '.tag_name' release.json)
VERSION=$(jq -r '.version' manifest.json)
ITEM_ID=$(jq -r '.id' manifest.json)

# tag may be prefixed with 'v' — strip it before comparing
if [ "${TAG#v}" != "$VERSION" ]; then
  echo "::error::Release tag '${TAG}' does not match manifest version '${VERSION}'"
  exit 1
fi

ZIP="${ITEM_ID}-${VERSION}.zip"
ASSET_NAMES=$(jq -r '.assets[].name' release.json)

echo "$ASSET_NAMES" | grep -qx "manifest.json" \
  || { echo "::error::Release '${TAG}' is missing a 'manifest.json' asset"; exit 1; }

echo "$ASSET_NAMES" | grep -qx "$ZIP" \
  || { echo "::error::Release '${TAG}' is missing the ${LABEL} zip '${ZIP}'"; exit 1; }

if [ "${LABEL}" = "plugin" ]; then
  MANIFEST_VERSION=$(jq -r '.manifestVersion' manifest.json)

  if [ "${MANIFEST_VERSION}" != "1" ]; then
    echo "::error::manifestVersion must be 1 (got '${MANIFEST_VERSION}')"
    exit 1
  fi
fi
