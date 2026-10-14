#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${GODOT_PORT:-6550}"
START_SCRIPT="$ROOT_DIR/tools/dev/start_godot_mcp_editor.sh"
LOG_FILE="$ROOT_DIR/.codex-local/godot-editor.log"

if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
  echo "Godot MCP bridge already healthy on 127.0.0.1:$PORT"
  exit 0
fi

printf 'Godot MCP bridge is offline on 127.0.0.1:%s; starting it through the official project launcher...\n' "$PORT"

if ! bash "$START_SCRIPT"; then
  echo "Failed to start the Godot MCP editor through the official launcher." >&2
  if [[ -f "$LOG_FILE" ]]; then
    echo "--- Godot editor log tail ---" >&2
    tail -n 80 "$LOG_FILE" >&2 || true
    echo "--- end log tail ---" >&2
  fi
  exit 1
fi

# The editor launcher waits for the TCP listener, but allow a short stabilization
# window before an MCP client immediately starts its own asynchronous handshake.
for _ in $(seq 1 10); do
  if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
    sleep 1
    echo "Godot MCP bridge verified healthy on 127.0.0.1:$PORT"
    exit 0
  fi
  sleep 1
done

echo "Godot MCP launcher returned, but bridge health verification still failed on 127.0.0.1:$PORT." >&2
if [[ -f "$LOG_FILE" ]]; then
  echo "--- Godot editor log tail ---" >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  echo "--- end log tail ---" >&2
fi
exit 1
