#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/client"
LOCAL_DIR="$ROOT_DIR/.codex-local"
PROJECT_FILE="$PROJECT_DIR/project.godot"
MCP_PACKAGE="@satelliteoflove/godot-mcp@4.1.11"
PORT="${GODOT_PORT:-6550}"

mkdir -p "$LOCAL_DIR"

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Missing $PROJECT_FILE" >&2
  exit 1
fi

if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
  echo "Godot MCP bridge is already listening on 127.0.0.1:$PORT"
  exit 0
fi

if [[ ! -f "$PROJECT_DIR/addons/godot_mcp/plugin.cfg" ]]; then
  echo "Installing pinned Godot MCP addon locally..."
  npx -y "$MCP_PACKAGE" --install-addon "$PROJECT_DIR" --force
fi

BACKUP="$(mktemp)"
cp "$PROJECT_FILE" "$BACKUP"
restore_project() {
  if [[ -f "$BACKUP" ]]; then
    cp "$BACKUP" "$PROJECT_FILE"
    rm -f "$BACKUP"
  fi
}
trap restore_project EXIT

# Enable the editor plugin only for this virtual editor launch. The original
# project.godot is restored as soon as the bridge is listening, so Android does
# not gain a mandatory MCP editor dependency and local user changes are kept.
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

# Run a normal editor on a virtual X11 display. Do NOT use Godot --headless:
# godot-mcp is designed around a live EditorPlugin bridge.
xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --editor --path "$PROJECT_DIR" \
  --rendering-method gl_compatibility \
  --audio-driver Dummy \
  >"$LOG_FILE" 2>&1 &
PID=$!
printf '%s\n' "$PID" > "$PID_FILE"

printf 'Starting Godot editor (pid %s), waiting for MCP bridge on port %s...\n' "$PID" "$PORT"
for _ in $(seq 1 60); do
  if nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; then
    restore_project
    trap - EXIT
    echo "Godot MCP bridge is listening on 127.0.0.1:$PORT"
    echo "Editor log: $LOG_FILE"
    exit 0
  fi
  if ! kill -0 "$PID" >/dev/null 2>&1; then
    echo "Godot editor exited before the MCP bridge became ready." >&2
    tail -n 120 "$LOG_FILE" >&2 || true
    exit 1
  fi
  sleep 1
done

echo "Timed out waiting for the Godot MCP bridge." >&2
tail -n 120 "$LOG_FILE" >&2 || true
exit 1
