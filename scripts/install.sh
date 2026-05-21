#!/usr/bin/env bash
# BXD EventOps Agent — Linux/macOS installer bootstrap
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/BxD-io/eventops-agent/main/scripts/install.sh \
#     | bash -s -- --url https://api.eventops.bxd.com.br --key evpr_...
#
# Or download first:
#   curl -fsSL .../install.sh -o install.sh && chmod +x install.sh
#   sudo ./install.sh --url ... --key ...

set -euo pipefail

GITHUB_REPO="BxD-io/eventops-agent"
TELEGRAF_VERSION="1.33.0"

# ── Parse arguments ───────────────────────────────────────────────────────────

EVENTOPS_URL=""
REGISTRATION_KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)   EVENTOPS_URL="$2";        shift 2 ;;
        --key)   REGISTRATION_KEY="$2";    shift 2 ;;
        *)       echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$EVENTOPS_URL" || -z "$REGISTRATION_KEY" ]]; then
    echo "Usage: $0 --url <api-url> --key <registration-key>"
    exit 1
fi

# ── Detect OS and architecture ────────────────────────────────────────────────

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH_RAW="$(uname -m)"

case "$ARCH_RAW" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64)   ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH_RAW"; exit 1 ;;
esac

case "$OS" in
    linux)  ;;
    darwin) ;;
    *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

echo ""
echo "=================================================="
echo "  BXD EventOps Agent — Bootstrap ($OS/$ARCH)"
echo "=================================================="
echo ""

# ── Directories ───────────────────────────────────────────────────────────────

if [[ "$OS" == "linux" ]]; then
    BASE_DIR="/opt/eventops"
    AGENT_DIR="/etc/eventops"
    LOG_DIR="/var/log/eventops"
else
    BASE_DIR="$HOME/Library/Application Support/EventOps"
    AGENT_DIR="$HOME/.config/eventops"
    LOG_DIR="$BASE_DIR/logs"
fi

TELEGRAF_DIR="$BASE_DIR/telegraf"
AGENT_BIN="$AGENT_DIR/eventops-agent"

for dir in "$BASE_DIR" "$AGENT_DIR" "$TELEGRAF_DIR" "$LOG_DIR"; do
    mkdir -p "$dir"
done
echo "  [OK] Directories ready"

# ── Helper: download with progress ───────────────────────────────────────────

download() {
    local url="$1" dest="$2"
    if command -v curl &>/dev/null; then
        curl -fsSL --progress-bar "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -q --show-progress "$url" -O "$dest"
    else
        echo "[FAIL] curl or wget is required"; exit 1
    fi
}

# ── Download EventOps Agent ───────────────────────────────────────────────────

echo "  [....] Downloading EventOps Agent..."
AGENT_URL="https://github.com/$GITHUB_REPO/releases/latest/download/eventops-agent-$OS-$ARCH"
download "$AGENT_URL" "$AGENT_BIN"
chmod +x "$AGENT_BIN"
echo "  [ OK ] Agent: $AGENT_BIN"

# ── Download Telegraf ─────────────────────────────────────────────────────────

echo "  [....] Downloading Telegraf $TELEGRAF_VERSION..."
TMP_DIR="$(mktemp -d)"

if [[ "$OS" == "linux" ]]; then
    TELEGRAF_URL="https://github.com/influxdata/telegraf/releases/download/v$TELEGRAF_VERSION/telegraf-$TELEGRAF_VERSION_linux_${ARCH}.tar.gz"
    TELEGRAF_ARCHIVE="$TMP_DIR/telegraf.tar.gz"
    download "$TELEGRAF_URL" "$TELEGRAF_ARCHIVE"
    tar -xzf "$TELEGRAF_ARCHIVE" -C "$TMP_DIR"
    find "$TMP_DIR" -name "telegraf" -not -name "*.conf" -exec cp {} "$TELEGRAF_DIR/telegraf" \;
    chmod +x "$TELEGRAF_DIR/telegraf"
else
    # macOS: use the darwin binary
    TELEGRAF_URL="https://github.com/influxdata/telegraf/releases/download/v$TELEGRAF_VERSION/telegraf-$TELEGRAF_VERSION_darwin_${ARCH}.tar.gz"
    TELEGRAF_ARCHIVE="$TMP_DIR/telegraf.tar.gz"
    download "$TELEGRAF_URL" "$TELEGRAF_ARCHIVE"
    tar -xzf "$TELEGRAF_ARCHIVE" -C "$TMP_DIR"
    find "$TMP_DIR" -name "telegraf" -not -name "*.conf" -exec cp {} "$TELEGRAF_DIR/telegraf" \;
    chmod +x "$TELEGRAF_DIR/telegraf"
fi

rm -rf "$TMP_DIR"
echo "  [ OK ] Telegraf: $TELEGRAF_DIR/telegraf"

# ── Run agent install (self-registration) ────────────────────────────────────

echo ""
echo "  [....] Registering agent with EventOps portal..."
echo ""

"$AGENT_BIN" install --url "$EVENTOPS_URL" --key "$REGISTRATION_KEY"

echo ""
echo "=================================================="
echo "  Installation complete!"
echo "=================================================="
if [[ "$OS" == "linux" ]]; then
    echo "  Run: systemctl status eventops-agent"
fi
echo ""
