#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="$ROOT_DIR/.codex-local/godot-editor.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "No recorded Godot editor process."
  exit 0
fi

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" >/dev/null 2>&1; then
  kill "$PID" || true
  for _ in $(seq 1 10); do
    if ! kill -0 "$PID" >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
  done
fi

rm -f "$PID_FILE"
echo "Godot MCP editor stopped (or was already gone)."
