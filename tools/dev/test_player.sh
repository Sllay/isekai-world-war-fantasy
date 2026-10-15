#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
player_log=$(mktemp)
trap 'rm -f "$player_log"' EXIT
"${GODOT_BIN:-godot}" --headless --path client --script res://tests/player_tests.gd >"$player_log" 2>&1 || { cat "$player_log"; exit 1; }
cat "$player_log"
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$player_log"; then exit 1; fi
rg -q 'Player tests: [0-9]+ checks, 0 failures' "$player_log"
