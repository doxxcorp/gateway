# Examples

| File | What |
|------|------|
| `doxxGateway.conf.example` | Every config key documented (setup generates the real one) |
| `watcher-local.sh` | Custom watch loop for an agent on the gateway machine |
| `watcher-remote.sh` | Custom watch loop for an agent driving a remote gateway over ssh |

Before reaching for the shell watchers, know that the binary ships the wake
loop built in: `doxxGateway watch` follows the journal with a durable
cursor, prints one `NEWMSG <json>` line per inbound message, reconnects
itself, and `-exec CMD` spawns a handler per message (event JSON on stdin).
The scripts below are templates for setups where the built-in does not fit.

# Watcher notes

A watcher is a small background loop that polls the gateway's event journal
and prints a `NEWMSG` line for every inbound message, so an agent (or any
supervisor watching the loop's output) wakes the moment its human speaks
instead of polling by hand.

Both are templates: set the variables at the top, run them in the
background, and watch their stdout for lines starting with `NEWMSG`.

## The rules these scripts follow (all field-earned)

1. **Print events BEFORE advancing the cursor.** If the pipe back to your
   agent dies mid-flight, an already-advanced cursor means the message is
   gone forever; an unadvanced cursor means the next iteration re-emits it.
   Duplicate wakes are harmless. Lost wakes are not.
2. **The cursor is durable and client-owned.** These scripts keep it in a
   file (`agent-cursor`). The gateway never resets it; `journal.oldest` in
   `/v1/status` tells you if you fell behind retention.
3. **Hard timeout on every iteration.** A half-open TCP connection once
   wedged a watch loop for seven hours. `timeout` plus ssh keepalives means
   an iteration can hang for at most ~75 seconds before the loop retries.
4. **Errors go to a log file, never to /dev/null.** A watcher that cannot
   reach the gateway looks identical to a silent chat unless failures are
   visible somewhere.
5. **Long-poll waits cap at 25 seconds** (`wait=25`): tunnel-scoped
   connections live under a ~30s idle ceiling, so ask for less and loop.
6. **Resolve hostnames outside the loop** (remote variant). Some host
   policies deny DNS to background process trees while foreground shells
   resolve fine; jumping by IP keeps the loop deaf-proof.

## Reading the output

```
NEWMSG [doxx] kind=text seq=6 chat_seq=10: Welcome! ...
```

- `seq` is the journal cursor value for this event (your resume point).
- `chat_seq` is what you pass to `POST /v1/chat/read` (with the sender's
  cert) after you have actually processed the message.
- Media arrives as `kind=media` with pointer JSON in the body; fetch bytes
  via `GET /v1/chat/media/<id>`.

Everything else about the API is self-teaching: `GET /v1/help` with your
credentials is the complete, current instruction set.
