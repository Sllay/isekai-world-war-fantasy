#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/client"
LOCAL_DIR="$ROOT_DIR/.codex-local"
PROJECT_FILE="$PROJECT_DIR/project.godot"
BACKUP_FILE="$LOCAL_DIR/project.godot.before-mcp"
PORT="${GODOT_PORT:-6550}"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

mkdir -p "$LOCAL_DIR"
export PATH="/usr/local/bin:$PATH"

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Missing $PROJECT_FILE" >&2
  exit 1
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Expected prepared Godot binary at $GODOT_BIN." >&2
  echo "Rebuild/run the project environment Install script before FULL startup." >&2
  exit 2
fi

GODOT_VERSION="$($GODOT_BIN --version 2>/dev/null || true)"
if [[ "$GODOT_VERSION" != 4.7.2* ]]; then
  echo "Expected Godot 4.7.2 at $GODOT_BIN, found '$GODOT_VERSION'." >&2
  echo "Rebuild/run the project environment Install script before FULL startup." >&2
  exit 2
fi

missing_libs=()
for lib in libxkbcommon.so.0 libdbus-1.so.3; do
  if ! ldconfig -p 2>/dev/null | grep -Fq "$lib"; then
    missing_libs+=("$lib")
  fi
done
if (( ${#missing_libs[@]} > 0 )); then
  printf 'Missing Godot runtime libraries: %s\n' "${missing_libs[*]}" >&2
  echo "Rebuild/run the project environment Install script; it installs the required native libraries." >&2
  exit 2
fi

if ! command -v godot-mcp >/dev/null 2>&1; then
  echo "godot-mcp is not installed on PATH. Rebuild/run the environment Install script." >&2
  exit 2
fi

if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
  echo "Godot MCP bridge is already listening on 127.0.0.1:$PORT"
  exit 0
fi

# Recover cleanly after a previous interrupted/crashed MCP session.
if [[ -f "$BACKUP_FILE" ]]; then
  echo "Recovering project.godot from a previous interrupted MCP session..."
  cp "$BACKUP_FILE" "$PROJECT_FILE"
  rm -f "$BACKUP_FILE"
fi

if [[ ! -f "$PROJECT_DIR/addons/godot_mcp/plugin.cfg" ]]; then
  echo "Installing pinned Godot MCP addon from the preinstalled CLI..."
  godot-mcp --install-addon "$PROJECT_DIR" --force
fi

cp "$PROJECT_FILE" "$BACKUP_FILE"

restore_on_failure() {
  if [[ -f "$BACKUP_FILE" ]]; then
    cp "$BACKUP_FILE" "$PROJECT_FILE"
    rm -f "$BACKUP_FILE"
  fi
}
trap restore_on_failure ERR INT TERM

python3 - "$PROJECT_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
plugin = 'res://addons/godot_mcp/plugin.cfg'

section_match = re.search(r'(?ms)^\[editor_plugins\]\n(?P<body>.*?)(?=^\[|\Z)', text)
if section_match is None:
    if not text.endswith("\n"):
        text += "\n"
    text += f'\n[editor_plugins]\nenabled=PackedStringArray("{plugin}")\n'
else:
    body = section_match.group("body")
    enabled_match = re.search(r'(?m)^enabled=PackedStringArray\((?P<items>.*)\)\s*$', body)
    if enabled_match is None:
        new_body = f'enabled=PackedStringArray("{plugin}")\n' + body
    elif plugin in enabled_match.group("items"):
        new_body = body
    else:
        items = enabled_match.group("items").strip()
        merged = f'{items}, "{plugin}"' if items else f'"{plugin}"'
        start, end = enabled_match.span()
        new_body = body[:start] + f'enabled=PackedStringArray({merged})' + body[end:]
    text = text[:section_match.start("body")] + new_body + text[section_match.end("body"):]

path.write_text(text, encoding="utf-8")
PY

LOG_FILE="$LOCAL_DIR/godot-editor.log"
PID_FILE="$LOCAL_DIR/godot-editor.pid"
: > "$LOG_FILE"

LIBGL_ALWAYS_SOFTWARE=1 \
GALLIUM_DRIVER=llvmpipe \
xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT_BIN" --editor --path "$PROJECT_DIR" \
  --rendering-method gl_compatibility \
  --audio-driver Dummy \
  >"$LOG_FILE" 2>&1 &
PID=$!
printf '%s\n' "$PID" > "$PID_FILE"

printf 'Starting Godot editor (pid %s), waiting for MCP bridge on port %s...\n' "$PID" "$PORT"
for _ in $(seq 1 60); do
  if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
    trap - ERR INT TERM
    echo "Godot MCP bridge is listening on 127.0.0.1:$PORT"
    echo "Editor log: $LOG_FILE"
    exit 0
  fi
  if ! kill -0 "$PID" >/dev/null 2>&1; then
    echo "Godot editor exited before the MCP bridge became ready." >&2
    tail -n 120 "$LOG_FILE" >&2 || true
    restore_on_failure
    exit 1
  fi
  sleep 1
done

echo "Timed out waiting for the Godot MCP bridge." >&2
tail -n 120 "$LOG_FILE" >&2 || true
kill "$PID" >/dev/null 2>&1 || true
restore_on_failure
exit 1
