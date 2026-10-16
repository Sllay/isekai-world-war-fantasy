#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
defense_test_dir=$(mktemp -d)
defense_test_log=$(mktemp)
trap 'rm -rf -- "$defense_test_dir"; rm -f -- "$defense_test_log"' EXIT
run_checked() {
  timeout 90 "${GODOT_BIN:-godot}" --headless --path client --script "$1" -- "${@:2}" >"$defense_test_log" 2>&1 || { cat "$defense_test_log"; return 1; }
  cat "$defense_test_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$defense_test_log"; then return 1; fi
  rg -q 'tests: [0-9]+ checks, 0 failures' "$defense_test_log"
}
run_checked res://tests/defensive_verbs_tests.gd "$defense_test_dir"
run_checked res://tests/vertical_recovery_tests.gd "$defense_test_dir"
for phase in save resume; do
  run_checked res://tests/defense_restart_process.gd "$phase" "$defense_test_dir"
done
