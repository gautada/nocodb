#!/bin/sh
#
# Fetches the latest stable NocoDB release version from GitHub.
# Prefers the version recorded in packages/nocodb/package.json for that tag,
# falling back to the tag name if the package manifest cannot be read.
# Strips any leading 'v' prefix and whitespace from the final result.

set -eu

RELEASE_API="https://api.github.com/repos/nocodb/nocodb/releases/latest"
TAG=$(curl -sL "$RELEASE_API" | jq -r '.tag_name' | tr -d '[:space:]')

if [ -z "$TAG" ] || [ "$TAG" = "null" ]; then
  echo "Failed to retrieve latest NocoDB release tag" >&2
  exit 1
fi

PACKAGE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/nocodb/nocodb/${TAG}/packages/nocodb/package.json" \
  | jq -r '.version' \
  | tr -d '[:space:]' \
  || true)

if [ -n "$PACKAGE_VERSION" ] && [ "$PACKAGE_VERSION" != "null" ]; then
  LATEST=$PACKAGE_VERSION
else
  LATEST=$(printf '%s' "$TAG" | sed 's/^v//')
fi

LATEST=$(printf '%s' "$LATEST" | tr -d '[:space:]')

if [ -z "$LATEST" ]; then
  echo "Failed to determine latest NocoDB release version" >&2
  exit 1
fi

printf '%s\n' "$LATEST"
