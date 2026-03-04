#!/bin/sh
#
# Health check: verifies NocoDB is responding on port 8080.
# Probes the /api/v1/health endpoint which returns JSON {status: "ok"}.
# Returns 0 if NocoDB is healthy, non-zero otherwise.

HEALTH=$(curl -sf --max-time 10 http://localhost:8080/api/v1/health 2>/dev/null)
if [ -z "$HEALTH" ]; then
  echo "nocodb-running: NocoDB health endpoint not responding on port 8080"
  exit 1
fi

STATUS=$(printf '%s' "$HEALTH" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "ok" ]; then
  echo "nocodb-running: NocoDB is healthy (status=ok)"
  exit 0
fi

echo "nocodb-running: NocoDB health check returned unexpected status: $HEALTH"
exit 1
