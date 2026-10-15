#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
world_log=$(mktemp)
trap 'rm -f "$world_log"' EXIT
"${GODOT_BIN:-godot}" --headless --path client --script res://tests/world_tests.gd >"$world_log" 2>&1 || { cat "$world_log"; exit 1; }
cat "$world_log"
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$world_log"; then exit 1; fi
rg -q 'World tests: [0-9]+ checks, 0 failures' "$world_log"
