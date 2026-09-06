#!/usr/bin/env bash
#
# doxx.net Gateway installer: fetches the latest release binary for this
# machine's architecture, verifies it against SHA256SUMS, and installs it
# to /usr/local/bin/doxxGateway.
#
#   curl -fsSL https://raw.githubusercontent.com/doxxcorp/gateway/main/install.sh | sudo bash
#
# No configuration happens here. After installing, run:
#   sudo doxxGateway setup -token <bot_token> -server <server_name> -name "<bot name>"

set -euo pipefail

REPO="doxxcorp/gateway"
BASE="https://github.com/${REPO}/releases/latest/download"
INSTALL_PATH="/usr/local/bin/doxxGateway"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root (the install target is ${INSTALL_PATH})." >&2
    exit 1
fi

case "$(uname -s)" in
    Linux) ;;
    *) echo "This installer is Linux-only. On a Mac, use the doxx.net app (Settings > Agent Gateway)." >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m) (releases ship linux amd64 + arm64)" >&2; exit 1 ;;
esac

ASSET="doxxGateway-linux-${ARCH}.gz"
TMP="$(mktemp -d -t doxxgw-install.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching ${ASSET} and SHA256SUMS from the latest release..."
curl -fsSL -o "${TMP}/${ASSET}" "${BASE}/${ASSET}"
curl -fsSL -o "${TMP}/SHA256SUMS" "${BASE}/SHA256SUMS"

echo "Verifying checksum..."
( cd "$TMP" && grep " ${ASSET}\$" SHA256SUMS | sha256sum -c - )

echo "Installing..."
gunzip -f "${TMP}/${ASSET}"
install -m 0755 "${TMP}/doxxGateway-linux-${ARCH}" "$INSTALL_PATH"

echo
echo "Installed $("$INSTALL_PATH" -h 2>&1 | head -1 || echo doxxGateway) to ${INSTALL_PATH}"
echo
echo "Next steps (one-step setup - no separate bot creation):"
echo "  1. Pick a server (no auth): curl -s -X POST https://config.doxx.net/v1/ -d \"servers=1\""
echo "  2. Set up with YOUR OWN doxx.net token (admin or net-admin, P2P plan)."
echo "     Setup creates the agent, provisions the tunnel, and mints the"
echo "     device credential; your token is used online only, never stored:"
echo "       sudo doxxGateway setup -token <YOUR_TOKEN> -server <server_name> -name \"<agent name>\""
echo "     Already on doxx.net for SSH? Add -ride to bind the agent to the"
echo "     existing link instead of building a second interface."
echo "  3. sudo doxxGateway run   (or install the systemd units, see the README)"
echo "  4. Paste the printed agent bundle to your agent."
