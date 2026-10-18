#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_VERSION="4.7.2"
GODOT_TAG="${GODOT_VERSION}-stable"
MCP_PACKAGE="@satelliteoflove/godot-mcp@4.1.11"
DIAGNOSTICS_MCP_PACKAGE="@ryanmazzolini/minimal-godot-mcp@0.1.6"
SERENA_PACKAGE="serena-agent==2.0.0"

log() {
  printf '\n[bootstrap] %s\n' "$*"
}

log "Installing Linux packages required by Godot + Xvfb..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip xauth xvfb netcat-openbsd ripgrep \
  libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libxkbcommon0 libxkbcommon-x11-0 libdbus-1-3 \
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

node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
if (( node_major < 22 )); then
  echo "Node.js 22+ is required by the diagnostic MCP; found $(node --version)." >&2
  echo "Rebuild the devcontainer so .devcontainer/devcontainer.json installs Node 22." >&2
  exit 1
fi

log "Installing/updating Codex CLI for the Codespace user..."
npm install -g @openai/codex@latest

log "Installing uv + pinned Serena semantic tooling..."
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv >/dev/null 2>&1; then
  echo "uv was installed but is not available on PATH." >&2
  exit 1
fi
if uv tool list | grep -q '^serena-agent '; then
  uv tool install -p 3.13 --force "$SERENA_PACKAGE"
else
  uv tool install -p 3.13 "$SERENA_PACKAGE"
fi

log "Validating pinned Godot MCP packages..."
npx -y "$MCP_PACKAGE" --version
npm view "$DIAGNOSTICS_MCP_PACKAGE" version >/dev/null

log "Installing the pinned runtime MCP addon locally into client/ (ignored by Git)..."
npx -y "$MCP_PACKAGE" --install-addon "$ROOT_DIR/client" --force

mkdir -p "$ROOT_DIR/.codex-local"

log "Environment versions"
printf 'Godot: '; godot --version
printf 'Node: '; node --version
printf 'npm: '; npm --version
printf 'Codex: '; codex --version || true
printf 'Serena: '; serena --version || true
printf 'Godot runtime MCP: '; npx -y "$MCP_PACKAGE" --version
printf 'Godot diagnostics MCP: '; npm view "$DIAGNOSTICS_MCP_PACKAGE" version

cat <<'EOF'

Codespace bootstrap complete.

First-time order:
  1. Run `codex`, complete ChatGPT sign-in, then EXIT Codex.
  2. Start virtual Godot editor: bash tools/dev/start_godot_mcp_editor.sh
  3. Verify development health:  bash tools/dev/devctl.sh health
  4. Verify the full runtime MCP: node tools/dev/mcp_smoke_test.mjs
  5. Check configured MCP servers: codex mcp list
  6. Start `codex` again for real work.

Expected Codex MCP layers:
  - serena: semantic GDScript symbols/references/edits via Godot LSP;
  - godot_diagnostics: lightweight GDScript diagnostics + DAP console;
  - godot: full editor/runtime control.

Serena requires the Godot editor/LSP to be active for GDScript semantic features.
The runtime smoke test must run before a Codex session holds the single live Godot MCP connection.
Do not forward ports 6550/6008 publicly. Godot editor bridges should remain localhost/private.
EOF
