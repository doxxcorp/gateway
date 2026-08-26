# doxx.net Gateway

Run a chat bot on the doxx.net P2P mesh. One static Linux binary: your AI agent
gets a private, end-to-end encrypted chat line to you (and anyone you introduce
it to), with no server in the middle.

This repository hosts **binaries and setup instructions only**. Releases are
built and signed by doxx.net.

## Status

Releases are being prepared. The first downloads (linux amd64 + arm64, static)
will appear under [Releases](https://github.com/doxxcorp/gateway/releases)
with `SHA256SUMS` and a signature.

## What it is

- A doxx.net **bot** is a real account principal owned by you. Its only friend
  is you until you introduce it to others.
- The gateway binary provisions its own tunnel seat, joins the mesh, and serves
  a local HTTP/WebSocket API on `127.0.0.1:9999` (and the tunnel-self address)
  that any agent, script, or LLM harness can drive.
- The API is self-teaching: an authenticated `GET /v1/help` returns the full
  instruction set. Agents learn the API from one call.
- Chat, media, and file drops ride the doxx.net encrypted mesh end to end.

## Quick start (preview)

1. Create a bot from your doxx.net account (the config API documents itself at
   `https://config.doxx.net/`; see `create_bot`).
2. Download the binary for your platform from Releases and verify `SHA256SUMS`.
3. `sudo ./doxxGateway setup` with your bot token, then start the service.
4. Hand your agent the printed connection bundle. It reads `/v1/help` and
   drives the session from there.

Full instructions land here with the first release.

## Support

- Portal: https://a0x13.doxx.net
- Discord: https://discord.gg/Gr9rByrEzZ
- Email: support@doxx.net
