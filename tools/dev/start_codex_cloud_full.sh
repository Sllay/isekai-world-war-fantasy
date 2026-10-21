#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_DIR="$ROOT_DIR/.codex-local"
MODE_FILE="$LOCAL_DIR/codex-cloud-mode"
mkdir -p "$LOCAL_DIR"
cd "$ROOT_DIR"
export PATH="/usr/local/bin:$PATH"
export GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

printf 'DEGRADED\n' > "$MODE_FILE"

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing prepared command: $name" >&2
    echo "Rebuild/run the Codex Cloud environment Install script, then start a new task." >&2
    exit 2
  fi
}

require_command node
require_command serena
require_command godot-mcp
require_command minimal-godot-mcp

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Missing prepared Godot binary: $GODOT_BIN" >&2
  echo "Rebuild/run the Codex Cloud environment Install script, then start a new task." >&2
  exit 2
fi
GODOT_VERSION="$($GODOT_BIN --version 2>/dev/null || true)"
if [[ "$GODOT_VERSION" != 4.7.2* ]]; then
  echo "Expected prepared Godot 4.7.2, found '$GODOT_VERSION'." >&2
  echo "Rebuild/run the Codex Cloud environment Install script, then start a new task." >&2
  exit 2
fi

# The environment Start skill runs in the task lifecycle, so services started
# here are expected to remain available while the task is active.
bash tools/dev/start_godot_mcp_editor.sh

# Fail the FULL promotion if the live editor/LSP bridge itself is unavailable.
bash tools/dev/devctl.sh mcp-status
node tools/dev/mcp_smoke_test.mjs

printf 'FULL\n' > "$MODE_FILE"
cat <<'EOF'
Codex Cloud live startup result: FULL
Godot 4.7.2 editor + LSP + runtime MCP bridge are reachable.
Serena and diagnostics/runtime MCP launchers are preinstalled on stable PATH.
EOF
