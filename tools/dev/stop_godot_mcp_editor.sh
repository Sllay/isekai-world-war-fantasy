#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_DIR="$ROOT_DIR/.codex-local"
PROJECT_FILE="$ROOT_DIR/client/project.godot"
BACKUP_FILE="$LOCAL_DIR/project.godot.before-mcp"
PID_FILE="$LOCAL_DIR/godot-editor.pid"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE")"
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" || true
    for _ in $(seq 1 20); do
      if ! kill -0 "$PID" >/dev/null 2>&1; then
        break
      fi
      sleep 0.25
    done
  fi
  rm -f "$PID_FILE"
fi

if [[ -f "$BACKUP_FILE" ]]; then
  cp "$BACKUP_FILE" "$PROJECT_FILE"
  rm -f "$BACKUP_FILE"
  echo "Restored client/project.godot after MCP editor session."
fi

echo "Godot MCP editor stopped (or was already gone)."
