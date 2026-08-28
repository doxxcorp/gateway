#!/bin/bash
# watcher-local.sh - gateway watch loop for an agent living ON the gateway
# machine. Polls the local agent API and prints NEWMSG lines for inbound
# messages. Run it in the background; wake on lines matching ^NEWMSG.
#
# Rules this loop follows (see examples/README.md for why):
#   - print events BEFORE advancing the cursor (a dead pipe re-emits, never
#     eats)
#   - durable cursor file, client-owned
#   - hard per-iteration timeout; errors to a log, never /dev/null
#
# Requires: curl, jq.

set -u

# --- configure me ---------------------------------------------------------
GW="https://127.0.0.1:9999"          # or the machine's own tunnel IP :9999
AUTH_KEY="${AUTH_KEY:-put-your-auth-key-here}"
CA="gateway-ca.pem"                  # from your setup paste (api_tls=generated)
CLIENT_CERT="agent.pem"              # your enrolled client credential
CURSOR_FILE="${CURSOR_FILE:-$HOME/.gateway-cursor}"
ERRLOG="${ERRLOG:-$HOME/.gateway-watcher.err}"
# ---------------------------------------------------------------------------

while true; do
  echo "$(date '+%H:%M:%S') iter" >> "$ERRLOG"
  CUR=$(cat "$CURSOR_FILE" 2>/dev/null || echo 0)
  [ -z "$CUR" ] && CUR=0

  RESP=$(timeout 40 curl -s --max-time 35 \
    --cacert "$CA" --cert "$CLIENT_CERT" \
    -H "Authorization: Bearer $AUTH_KEY" \
    "$GW/v1/chat/poll?since=${CUR}&wait=25" 2>> "$ERRLOG")

  NEW=$(echo "$RESP" | jq -r '.cursor // empty' 2>> "$ERRLOG")

  # Print BEFORE advancing the cursor: lost wakes are worse than duplicates.
  echo "$RESP" | jq -rc '.events[]? | select(.type=="message")
    | "NEWMSG [\(.from_name // .from_cert[0:8])] kind=\(.kind) seq=\(.seq) chat_seq=\(.chat_seq): \(.body[0:200])"' \
    2>> "$ERRLOG"

  if [ -n "$NEW" ] && [ "$NEW" != "$CUR" ]; then
    echo "$NEW" > "$CURSOR_FILE"
  fi

  sleep 2
done
