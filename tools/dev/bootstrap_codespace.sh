#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_VERSION="4.7.2"
GODOT_TAG="${GODOT_VERSION}-stable"
MCP_PACKAGE="@satelliteoflove/godot-mcp@4.1.11"

log() {
  printf '\n[bootstrap] %s\n' "$*"
}

log "Installing Linux packages required by Godot + Xvfb..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip xauth xvfb netcat-openbsd \
  libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libgl1 libgl1-mesa-dri libfontconfig1 libasound2t64

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)
    GODOT_ARCH="x86_64"
    GODOT_SHA256="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
    ;;
  aarch64|arm64)
    GODOT_ARCH="arm64"
    GODOT_SHA256="5dd0d86405cf7e8adf79fb6377b38ba682a2846cb378ffe5364f38c01ad29b9d"
    ;;
  *)
    echo "Unsupported Codespace architecture: $ARCH" >&2
    exit 1
    ;;
esac

if command -v godot >/dev/null 2>&1 && godot --version | grep -q "^${GODOT_VERSION}"; then
  log "Godot ${GODOT_VERSION} already installed."
else
  log "Installing exact Godot ${GODOT_VERSION} (${GODOT_ARCH})..."
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  ZIP_NAME="Godot_v${GODOT_TAG}_linux.${GODOT_ARCH}.zip"
  URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/${ZIP_NAME}"
  curl -L --fail --retry 3 --retry-delay 2 "$URL" -o "$TMP_DIR/godot.zip"
  printf '%s  %s\n' "$GODOT_SHA256" "$TMP_DIR/godot.zip" | sha256sum -c -
  unzip -q "$TMP_DIR/godot.zip" -d "$TMP_DIR/godot"
  GODOT_BIN="$(find "$TMP_DIR/godot" -maxdepth 1 -type f -name 'Godot_v*-stable_linux.*' | head -n 1)"
  if [[ -z "$GODOT_BIN" ]]; then
    echo "Godot binary not found after extraction." >&2
    exit 1
  fi
  sudo install -m 0755 "$GODOT_BIN" /usr/local/bin/godot
  rm -rf "$TMP_DIR"
  trap - EXIT
fi

log "Installing/updating Codex CLI..."
sudo npm install -g @openai/codex@latest

log "Validating pinned Godot MCP package..."
npx -y "$MCP_PACKAGE" --version

log "Installing the pinned MCP addon locally into client/ (ignored by Git)..."
npx -y "$MCP_PACKAGE" --install-addon "$ROOT_DIR/client" --force

mkdir -p "$ROOT_DIR/.codex-local"

log "Environment versions"
printf 'Godot: '; godot --version
printf 'Node: '; node --version
printf 'npm: '; npm --version
printf 'Codex: '; codex --version || true
printf 'Godot MCP: '; npx -y "$MCP_PACKAGE" --version

cat <<'EOF'

Codespace bootstrap complete.

Next:
  1. Sign in to Codex once:        codex
  2. Start virtual Godot editor:   bash tools/dev/start_godot_mcp_editor.sh
  3. Verify the full MCP chain:    node tools/dev/mcp_smoke_test.mjs
  4. Check Codex MCP config:       codex mcp list

Do not forward port 6550 publicly. The Godot MCP bridge should remain localhost-only.
EOF
