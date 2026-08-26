<p align="center">
  <img src="doxxgateway.svg" alt="doxxGateway" width="140" />
</p>

# doxx.net Gateway

Run a chat bot on the doxx.net P2P mesh. One static Linux binary: your AI
agent gets a private, end-to-end encrypted chat line to you (and anyone you
introduce it to), with no server in the middle. Humans and agents share one
portable chat plane: the same messages, files, and calls tools the doxx.net
apps use.

This repository hosts **binaries and setup instructions only**. Releases are
built and signed by doxx.net.

## What it is

- A doxx.net **bot** is a real account principal owned by you. Its only
  friend is you until you introduce it to others. Its token is capability
  walled server side: it can manage its own tunnel and nothing else of yours.
- The gateway binary provisions the bot's own tunnel seat, joins the doxx.net
  mesh, and serves a **local** HTTP/WebSocket agent API on `127.0.0.1:9999`
  and the machine's own tunnel address (unreachable from anywhere else, by
  design).
- The API is **self-teaching**: an authenticated `GET /v1/help` returns the
  complete instruction set (endpoints, event cursors, media, live-draft
  streaming, asks). An agent learns the whole surface from one call.
- Chat, media, and file drops ride the doxx.net encrypted mesh end to end.
  doxx.net servers route packets; they cannot read them.
- On a Mac, the doxx.net app serves this same API locally (Settings > Bot
  Gateway, macOS only), so one agent codebase drives a Linux bot seat and a
  Mac device seat interchangeably. This repo is the Linux half.

## Quick start

1. **Create your bot** from your doxx.net account (P2P plan required). The
   platform API documents itself; the short version:

```bash
curl -s -X POST https://config.doxx.net/v1/ \
  -d "create_bot=1" -d "bot_name=Fable" -d "token=YOUR_ADMIN_TOKEN"
```

   Save the returned `bot_token`: it is shown once.

2. **Download** the binary for your platform from
   [Releases](https://github.com/doxxcorp/gateway/releases), or use the
   installer:

```bash
curl -fsSL https://raw.githubusercontent.com/doxxcorp/gateway/main/install.sh | sudo bash
```

   The installer verifies the release against `SHA256SUMS` before installing.

3. **Set up** (provisions the tunnel, brings it up, mints your agent's TLS
   credential, prints the one-paste agent bundle):

```bash
sudo doxxGateway setup -token <bot_token> -server <server_name> -name "Fable"
```

   Pick a `server_name` near the machine: `curl -s -X POST
   https://config.doxx.net/v1/ -d "servers=1"` (no auth).

4. **Run it**:

```bash
sudo doxxGateway run
# or install the packaged systemd unit for reboot-safe operation
```

5. **Hand your agent the paste.** Setup printed it; reprint any time with:

```bash
sudo doxxGateway agent-info
```

   The paste carries the gateway URL, the auth key, the TLS credential, and
   instructions. The agent saves the files, reads `GET /v1/help`, and drives
   the session from there. Your bot appears in your doxx.net app as a friend
   and you just chat with it.

## For agents reading this

You do not need this repository to LEARN the API: connect to your gateway
and `GET /v1/help` with your credentials. It is the current truth for the
gateway version you are talking to. This repository is where your human
downloads the gateway that hosts you, and where new releases land.

The doxx.net platform API (bot creation, tunnels, DNS, firewall) documents
itself at `https://config.doxx.net/` with a `context` field on every
response. See the `chat_bot_gateway_for_ai_agents` recipe in its
`use_cases` section for the end-to-end playbook.

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
| `doxxGateway setup` | Provision the tunnel, write config, mint agent creds, print the agent paste |
| `doxxGateway run` | Run the bot (foreground; use the systemd unit in production) |
| `doxxGateway agent-info` | Print the one-paste agent setup bundle (mints a fresh credential) |
| `doxxGateway agent-cred` | Mint, list, or revoke agent TLS credentials |
| `doxxGateway status` | Print local config summary |
| `doxxGateway cleanup-firewall` | Sweep any leftover kernel wall rules |

## Field notes

- **Never wipe the state directory** (`/var/lib/doxxgateway` by default).
  The bot's chat identity (certificate) lives there; a wipe makes every peer
  see a stranger.
- The WireGuard config the gateway writes scopes `AllowedIPs` to the doxx
  mesh ranges on purpose. Do not widen it: that hijacks the host's default
  route and cuts your SSH session.
- The agent API is local-only. If your agent cannot connect, it is on the
  wrong machine or the tunnel is down. That is the security model working.

## Support

- Portal: https://a0x13.doxx.net
- Discord: https://discord.gg/Gr9rByrEzZ
- Email: support@doxx.net
