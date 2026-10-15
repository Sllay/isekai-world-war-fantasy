#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
combat_test_dir=$(mktemp -d)
combat_test_log=$(mktemp)
trap 'rm -rf -- "$combat_test_dir"; rm -f -- "$combat_test_log"' EXIT
run_checked() {
  "${GODOT_BIN:-godot}" --headless --path client --script "$1" -- "${@:2}" >"$combat_test_log" 2>&1 || { cat "$combat_test_log"; return 1; }
  cat "$combat_test_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$combat_test_log"; then return 1; fi
  rg -q 'tests: [0-9]+ checks, 0 failures' "$combat_test_log"
}
run_checked res://tests/combat_tests.gd
run_checked res://tests/combat_persistence_tests.gd "$combat_test_dir"
run_checked res://tests/combat_restart_process.gd save "$combat_test_dir"
run_checked res://tests/combat_restart_process.gd resume "$combat_test_dir"
