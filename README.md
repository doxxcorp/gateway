<p align="center">
  <img src="doxxgateway.svg" alt="doxxGateway" width="140" />
</p>

# doxx.net Gateway

Give an AI agent a private, end-to-end encrypted chat line to you (and anyone
you introduce it to) over the doxx.net P2P mesh, with no server in the middle.
Humans and agents share one portable chat plane: the same messages, files, and
live-typing tools the doxx.net apps use.

This repository hosts **binaries and setup instructions only**. Releases are
built and signed by doxx.net.

## What it is

- A doxx.net **agent** is an owned sub-friend of your account, not a separate
  account. The machine hosting it joins as one of your devices (one normal
  device seat), and the agent is a chat principal bound to that device. You
  see every conversation your agent has. Friends who link with it see it as
  `(AgentName)you@machine`.
- **Reach is double opt-in, and you mediate every step.** A new agent is
  OWNER-ONLY: it talks to you and nobody else until you set `owner_only=off`
  in its config. After that, each contact takes two consents: the person must
  be your active friend (necessary, never sufficient), AND they must
  explicitly accept your agent through an introduction you drive. Your agent
  can also ask for a contact by name (`POST /v1/contacts`); you get a
  forwardable request card and the friend still decides. Being your friend
  never grants an agent anything by itself, and everything is enforced
  server-side, not by the binary.
- The host machine never holds an account credential: setup uses your token
  online only and stores a role=device credential that can fetch its own
  tunnel config and act as the agent, nothing else.
- The gateway serves a **local** HTTP/WebSocket agent API on `127.0.0.1:9999`
  and the machine's own tunnel address. It does not exist for the mesh or the
  internet: three locks on one port (only this machine can reach it, only
  enrolled TLS client certificates get a connection, only the auth key gets
  an answer).
- The API is **self-teaching**: an authenticated `GET /v1/help` returns the
  complete instruction set (endpoints, event cursors, media, live-draft
  streaming, asks). An agent learns the whole surface from one call.

## Two ways to host an agent

**On a Mac: no binary needed, it is built into the doxx.net app.** Open
Settings > Bot Gateway (macOS only; agents do not run on phones yet, so
iPhones and iPads never see this screen), flip it on, and tap **Copy
everything for your agent**. That one tap builds the setup paste and puts it
on your clipboard: URL, auth key, a fresh TLS credential, and instructions.
Paste it to your agent and you are done. An agent hosted this way speaks AS
you (the Mac is your device), and its conversation targets are your friends.

**On a Linux server: this repository's binary, one setup command.** The agent
gets its own name, face, and identity on a dedicated device seat, stays
online around the clock, and speaks as itself: `(AgentName)you@machine`. The
quick start below is this path.

## Quick start (Linux)

1. **Download** the binary for your platform from
   [Releases](https://github.com/doxxcorp/gateway/releases), or use the
   installer (verifies the release against `SHA256SUMS` before installing):

```bash
curl -fsSL https://raw.githubusercontent.com/doxxcorp/gateway/main/install.sh | sudo bash
```

2. **Pick a server** near the machine (no auth needed):

```bash
curl -s -X POST https://config.doxx.net/v1/ -d "servers=1"
```

3. **Set up with your own doxx.net token** (admin or net-admin, P2P plan).
   One command does everything: creates the agent principal, provisions a
   device tunnel on your account, mints the scoped device credential and the
   agent's TLS credential, registers the device, and prints the one-paste
   agent bundle. Your token is used online during setup only and is never
   written to disk.

```bash
sudo doxxGateway setup -token <YOUR_TOKEN> -server <server_name> -name "Fable"
```

   Out of device seats? The error tells you the fix: free a seat, or add
   seats in the doxx.net app under Account > Subscription (or at
   https://a0x13.doxx.net/ops/account/subscription).

4. **Run it**:

```bash
sudo doxxGateway run
# or install the packaged systemd unit for reboot-safe operation
```

5. **Hand your agent the paste.** Setup printed it; reprint any time (mints
   a fresh credential) with:

```bash
sudo doxxGateway agent-info
```

   The paste carries the gateway URL, the auth key, the TLS credential
   files, and instructions. The agent saves the files, reads `GET /v1/help`,
   and drives the session from there:

```bash
curl -s --cacert gateway-ca.pem --cert agent.pem \
     -H "Authorization: Bearer $AUTH_KEY" https://<tunnel-ip>:9999/v1/status
```

   Your agent appears in your doxx.net app as a friend. You just chat with
   it.

## For agents reading this

You do not need this repository to LEARN the API: connect to your gateway
and `GET /v1/help` with your credentials. It is the current truth for the
gateway version you are talking to. This repository is where your human
downloads the gateway that hosts you, and where new releases land.

The doxx.net platform API (agent creation, tunnels, DNS, firewall) documents
itself at `https://config.doxx.net/` with a `context` field on every
response. See the `chat_bot_gateway_for_ai_agents` recipe in its `use_cases`
section for the end-to-end playbook.

## Releases

Each release ships:

| File | What |
|------|------|
| `doxxGateway-linux-amd64.gz` | Static linux/amd64 binary, gzipped |
| `doxxGateway-linux-arm64.gz` | Static linux/arm64 binary, gzipped |
| `SHA256SUMS` | Checksums for everything above |
| `SHA256SUMS.sig` | doxx.net release signature |

Pure Go, `CGO_ENABLED=0`: no runtime dependencies. Debian/RPM packages come
later.

## Commands

| Command | What |
|---------|------|
| `doxxGateway setup` | Create the agent, provision the tunnel, write config, mint credentials, print the agent paste |
| `doxxGateway run` | Run the agent host (foreground; use the systemd unit in production) |
| `doxxGateway agent-info` | Print the one-paste agent setup bundle (mints a fresh credential) |
| `doxxGateway agent-cred` | Mint, list, or revoke agent TLS credentials |
| `doxxGateway status` | Print local config summary |
| `doxxGateway cleanup-firewall` | Sweep any leftover kernel wall rules |

## MCP (Model Context Protocol)

The gateway speaks MCP natively, so agent runtimes plug in with zero glue.
Two transports, both local-only by design:

- **stdio** (no network surface at all): point your MCP client at the
  command `doxxGateway mcp`. Remote agents use ssh as the command:
  `ssh <box> doxxGateway mcp`. Works today in Cursor and Claude Desktop
  configs.
- **Loopback HTTP**: `http://127.0.0.1:9998/mcp` on the gateway machine
  (`mcp_listen` in the config; loopback addresses only, enforced), with the
  same Bearer auth key as the API.

Tools mirror the API one-to-one: `status`, `peers`, `chat_send`,
`wait_for_message` (your wake loop: long-poll with a cursor), `chat_poll`,
`chat_history`, `conversations`, `typing` (live drafts), `read_ack`, `ask`,
`media_send`, `media_get`, `contacts_list`, `contact_request`,
`netdrop_send`. The double opt-in trust model rides along: refusals arrive
as tool errors that explain themselves.

## The wake loop: doxxGateway watch

`doxxGateway watch` is the built-in watcher: it follows the journal, owns a
durable cursor, prints one `NEWMSG <json>` line per inbound message
(`-all` adds every event as `EVENT` lines), and reconnects itself. Spawn a
handler per message with `-exec CMD` (event JSON on stdin) and you have
push, not poll, with zero scripting - point it at your bot framework's
ingest hook. Remote agents just run `ssh <box> doxxGateway watch` and read
lines.

## Watcher examples

`examples/` ships shell templates for CUSTOM watch loops
(`watcher-local.sh`, `watcher-remote.sh`) if the built-in `doxxGateway
watch` does not fit your setup. They follow the same field-earned rules
(print events BEFORE advancing the cursor, hard per-iteration timeouts,
errors to a log, never to /dev/null).

## Field notes

- **Never wipe the state directory** (`/var/lib/doxxgateway` by default).
  The agent's chat identity (certificate) lives there; a wipe makes every
  peer see a stranger.
- `owner_only=on` is the default and the lockdown: the agent reaches you and
  nobody else, server-enforced. Set `owner_only=off` only when you want the
  double-opt-in introduction flows available.
- The WireGuard config the gateway writes scopes `AllowedIPs` to the doxx
  mesh ranges on purpose. Do not widen it to `0.0.0.0/0`: that hijacks the
  host's default route and cuts your SSH session.
- Chatting with devices that hold a **dedicated public IPv4**: those
  addresses sit outside the standard mesh ranges. Set `wg_sync=on` in the
  config and the gateway auto-routes peer addresses it learns from the mesh
  (host routes only, the default route is never touched). Know the
  trade-off: once enabled, this box answers those peers via the mesh, so
  plain-internet connections from such a device to this box's public address
  will ride the tunnel instead.
- Agent-to-agent chat is off by default. Enable `agent_chat=on` on both
  gateways and pair the agents with owner approval; owners see an activity
  pulse for agent threads.
- The agent API is local-only. If your agent cannot connect, it is on the
  wrong machine or the tunnel is down. That is the security model working.

## Support

- Portal: https://a0x13.doxx.net
- Discord: https://discord.gg/Gr9rByrEzZ
- Email: support@doxx.net
