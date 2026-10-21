#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_DIR="$ROOT_DIR/.codex-local"
MODE_FILE="$LOCAL_DIR/codex-cloud-mode"
mkdir -p "$LOCAL_DIR"
cd "$ROOT_DIR"

printf 'DEGRADED\n' > "$MODE_FILE"

# The environment Start skill runs in the task lifecycle, so services started
# here are expected to remain available while the task is active.
bash tools/dev/start_godot_mcp_editor.sh

# Fail the FULL promotion if the live editor/LSP bridge itself is unavailable.
bash tools/dev/devctl.sh mcp-status
node tools/dev/mcp_smoke_test.mjs

# Stable task-lifecycle prerequisites for project-scoped MCP launchers.
command -v godot >/dev/null
command -v node >/dev/null
command -v npx >/dev/null
command -v serena >/dev/null

printf 'FULL\n' > "$MODE_FILE"
cat <<'EOF'
Codex Cloud live startup result: FULL
Godot editor + LSP + runtime MCP bridge are reachable.
Project-scoped Serena/diagnostics MCP launchers are installed and on PATH.
EOF
