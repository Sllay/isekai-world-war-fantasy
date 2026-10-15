#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
save_test_dir=$(mktemp -d)
save_test_log=$(mktemp)
trap 'rm -rf -- "$save_test_dir"; rm -f -- "$save_test_log"' EXIT
run_checked() {
  "${GODOT_BIN:-godot}" --headless --path client --script "$1" -- "${@:2}" >"$save_test_log" 2>&1 || { cat "$save_test_log"; return 1; }
  cat "$save_test_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$save_test_log"; then return 1; fi
  rg -q 'tests: [0-9]+ checks, 0 failures' "$save_test_log"
}
run_checked res://tests/save_resume_tests.gd "$save_test_dir"
# Each invocation is a fresh OS process; only JSON files cross the boundary.
run_checked res://tests/save_restart_process.gd save "$save_test_dir"
run_checked res://tests/save_restart_process.gd resume "$save_test_dir"
run_checked res://tests/save_restart_process.gd exit "$save_test_dir"
