#!/bin/sh
#
# Returns the version of the installed NocoDB application.
# Reads directly from /usr/app/package.json using jq.
# Returns non-zero if the version cannot be determined.

VERSION=$(jq -r '.version' /usr/app/package.json 2>/dev/null | tr -d '[:space:]')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to read NocoDB version from /usr/app/package.json" >&2
  exit 1
fi

printf '%s\n' "$VERSION"
