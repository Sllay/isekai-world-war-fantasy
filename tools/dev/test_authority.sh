#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
authority_log=$(mktemp)
trap 'rm -f "$authority_log"' EXIT
"${GODOT_BIN:-godot}" --headless --path client --script res://tests/authority_tests.gd > "$authority_log" 2>&1 || { cat "$authority_log"; exit 1; }
cat "$authority_log"
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$authority_log"; then exit 1; fi
rg -q 'Authority tests: [1-9][0-9]* checks, 0 failures' "$authority_log"
"${GODOT_BIN:-godot}" --headless --path client --script res://tests/a1_scenario_tests.gd > "$authority_log" 2>&1 || { cat "$authority_log"; exit 1; }
cat "$authority_log"
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$authority_log"; then exit 1; fi
rg -q 'A1 scenario tests: [1-9][0-9]* checks, 0 failures' "$authority_log"
