#!/bin/bash
# watcher-remote.sh - gateway watch loop for an agent driving a REMOTE
# gateway over ssh. Each iteration sshes to the gateway host, polls the
# local-only agent API there, prints NEWMSG lines back, and keeps the
# cursor canonical ON the gateway host (any agent session can resume it).
#
# Rules this loop follows (see examples/README.md for why):
#   - print events BEFORE advancing the cursor (a killed ssh re-emits,
#     never eats)
#   - hard per-iteration timeout + ssh keepalives (a half-open ssh once
#     wedged a loop for seven hours)
#   - errors to a log, never /dev/null
#   - ssh by IP if your host denies DNS to background processes (some
#     macOS policies do exactly that while foreground shells resolve fine)
#
# Requires locally: ssh, timeout. Requires on the gateway host: curl, jq,
# and permission to read the gateway config (the auth key).

set -u

# --- configure me ---------------------------------------------------------
GW_HOST="user@203.0.113.7"            # the gateway machine (prefer an IP)
JUMP=""                                # optional: "-J user@jump-ip"
CONF="/etc/doxxgateway/doxxGateway.conf"
CREDS_DIR="/etc/doxxgateway"           # gateway-ca.pem + agent-1.pem live here
CURSOR_FILE="/var/lib/doxxgateway/agent-cursor"
ERRLOG="${ERRLOG:-$HOME/.gateway-watcher.err}"
SUDO="sudo"                            # "" if your user can read conf/cursor
# ---------------------------------------------------------------------------

REMOTE='
cd '"$CREDS_DIR"' || exit 1
AUTH=$('"$SUDO"' grep "^auth_key=" '"$CONF"' | cut -d= -f2)
CUR=$('"$SUDO"' cat '"$CURSOR_FILE"' 2>/dev/null || echo 0)
[ -z "$CUR" ] && CUR=0
RESP=$('"$SUDO"' curl -s --max-time 30 --cacert gateway-ca.pem --cert agent-1.pem \
  -H "Authorization: Bearer $AUTH" \
  "https://127.0.0.1:9999/v1/chat/poll?since=${CUR}&wait=25")
NEW=$(echo "$RESP" | jq -r ".cursor // empty")
# Print BEFORE advancing the cursor: a dead pipe must not eat messages.
echo "$RESP" | jq -rc ".events[]? | select(.type==\"message\") | \"NEWMSG [\(.from_name // .from_cert[0:8])] kind=\(.kind) seq=\(.seq) chat_seq=\(.chat_seq): \(.body[0:200])\""
if [ -n "$NEW" ] && [ "$NEW" != "$CUR" ]; then
  echo "$NEW" | '"$SUDO"' tee '"$CURSOR_FILE"' >/dev/null
fi
'

while true; do
  echo "$(date '+%H:%M:%S') iter" >> "$ERRLOG"
  # shellcheck disable=SC2086
  timeout 75 ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ConnectTimeout=10 \
    $JUMP "$GW_HOST" "$REMOTE" 2>> "$ERRLOG"
  sleep 2
done
