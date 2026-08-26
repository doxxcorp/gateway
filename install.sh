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
    *) echo "This installer is Linux-only. On a Mac, use the doxx.net app (Settings > Bot Gateway)." >&2; exit 1 ;;
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
echo "Next steps:"
echo "  1. Create a bot from your doxx.net account (see the README):"
echo "     curl -s -X POST https://config.doxx.net/v1/ -d \"create_bot=1\" -d \"bot_name=<name>\" -d \"token=<admin token>\""
echo "  2. sudo doxxGateway setup -token <bot_token> -server <server_name> -name \"<bot name>\""
echo "  3. sudo doxxGateway run"
echo "  4. Paste the printed agent bundle to your agent."
