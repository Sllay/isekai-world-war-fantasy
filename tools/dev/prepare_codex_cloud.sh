#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_DIR="$ROOT_DIR/.codex-local"
MODE_FILE="$LOCAL_DIR/codex-cloud-mode"
mkdir -p "$LOCAL_DIR"

printf 'DEGRADED\n' > "$MODE_FILE"

bash "$ROOT_DIR/tools/dev/bootstrap_codex_cloud.sh"

bash "$ROOT_DIR/tools/dev/devctl.sh godot-check"

if bash "$ROOT_DIR/tools/dev/start_godot_mcp_editor.sh"; then
  if bash "$ROOT_DIR/tools/dev/devctl.sh mcp-status" && node "$ROOT_DIR/tools/dev/mcp_smoke_test.mjs"; then
    printf 'FULL\n' > "$MODE_FILE"
    echo "Codex Cloud preparation result: FULL"
    exit 0
  fi

  echo "Codex Cloud live bridge probe was incomplete; stopping partial editor and continuing DEGRADED." >&2
  bash "$ROOT_DIR/tools/dev/stop_godot_mcp_editor.sh" || true
else
  echo "Codex Cloud could not establish virtual Godot editor; continuing DEGRADED." >&2
fi

printf 'DEGRADED\n' > "$MODE_FILE"
echo "Codex Cloud preparation result: DEGRADED"
echo "Headless Godot/tests remain available. Editor-dependent validation should use Codespace FULL if required."
exit 0
