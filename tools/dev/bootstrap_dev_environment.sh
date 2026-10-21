#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOST_KIND="${ISEKAI_DEV_HOST:-generic-linux}"
INSTALL_CODEX_CLI="${INSTALL_CODEX_CLI:-0}"
GODOT_VERSION="4.7.2"
GODOT_TAG="${GODOT_VERSION}-stable"
MCP_PACKAGE="@satelliteoflove/godot-mcp@4.1.11"
DIAGNOSTICS_MCP_PACKAGE="@ryanmazzolini/minimal-godot-mcp@0.1.6"
SERENA_PACKAGE="serena-agent==2.0.0"

log() { printf '\n[bootstrap:%s] %s\n' "$HOST_KIND" "$*"; }

run_root() {
  if [[ "$(id -u)" == "0" ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "Need root/sudo to install system packages on $HOST_KIND." >&2
    exit 1
  fi
}

log "Installing Linux packages required by Godot editor/Xvfb and diagnostics..."
run_root apt-get update -y
run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip xauth xvfb netcat-openbsd ripgrep python3 \
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
    echo "Unsupported development-host architecture: $ARCH" >&2
    exit 1
    ;;
esac

if [[ -x /usr/local/bin/godot ]] && /usr/local/bin/godot --version | grep -q "^${GODOT_VERSION}"; then
  log "Godot ${GODOT_VERSION} already installed at /usr/local/bin/godot."
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
  [[ -n "$GODOT_BIN" ]] || { echo "Godot binary not found after extraction." >&2; exit 1; }
  run_root install -m 0755 "$GODOT_BIN" /usr/local/bin/godot
  rm -rf "$TMP_DIR"
  trap - EXIT
fi

export PATH="/usr/local/bin:$PATH"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js 22+ is required. Configure Node in the host/environment before this bootstrap." >&2
  exit 1
fi
node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
if (( node_major < 22 )); then
  echo "Node.js 22+ is required; found $(node --version)." >&2
  exit 1
fi

if [[ "$INSTALL_CODEX_CLI" == "1" ]]; then
  log "Installing/updating Codex CLI for this host..."
  npm install -g @openai/codex@latest
fi

log "Installing pinned Godot MCP servers globally for offline task startup..."
# Codex Cloud task sandboxes may not have network access. Install the MCP
# executables during environment preparation so runtime startup never depends
# on npx fetching packages from the registry.
run_root env PATH="$PATH" npm install -g "$MCP_PACKAGE" "$DIAGNOSTICS_MCP_PACKAGE"
command -v godot-mcp >/dev/null 2>&1 || { echo "godot-mcp executable missing after install." >&2; exit 1; }
command -v minimal-godot-mcp >/dev/null 2>&1 || { echo "minimal-godot-mcp executable missing after install." >&2; exit 1; }

log "Installing uv + pinned Serena semantic tooling..."
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null 2>&1 || { echo "uv was installed but is not available on PATH." >&2; exit 1; }
if uv tool list | grep -q '^serena-agent '; then
  uv tool install -p 3.13 --force "$SERENA_PACKAGE"
else
  uv tool install -p 3.13 "$SERENA_PACKAGE"
fi
SERENA_BIN="$(command -v serena || true)"
[[ -n "$SERENA_BIN" ]] || { echo "Serena installed but executable was not found." >&2; exit 1; }
run_root ln -sf "$SERENA_BIN" /usr/local/bin/serena

log "Installing pinned runtime MCP addon locally into client/ (ignored by Git)..."
godot-mcp --install-addon "$ROOT_DIR/client" --force
mkdir -p "$ROOT_DIR/.codex-local"

log "Environment versions"
printf 'Host: %s\n' "$HOST_KIND"
printf 'Godot: '; /usr/local/bin/godot --version
printf 'Node: '; node --version
printf 'npm: '; npm --version
if command -v codex >/dev/null 2>&1; then printf 'Codex: '; codex --version || true; fi
printf 'Serena: '; /usr/local/bin/serena --version || true
printf 'Godot runtime MCP: '; godot-mcp --version || true
printf 'Godot diagnostics MCP: '; npm list -g --depth=0 "$DIAGNOSTICS_MCP_PACKAGE" 2>/dev/null | tail -n 1 || true

cat <<'EOF'

Host-neutral bootstrap complete.

Install/setup intentionally does not keep live Godot services running.
For Codex Cloud, the environment Start skill should run:
  bash tools/dev/start_codex_cloud_full.sh

For a persistent developer shell, the equivalent manual probe is:
  1. bash tools/dev/start_godot_mcp_editor.sh
  2. bash tools/dev/devctl.sh health
  3. node tools/dev/mcp_smoke_test.mjs

Never expose ports 6550/6008 publicly.
EOF
