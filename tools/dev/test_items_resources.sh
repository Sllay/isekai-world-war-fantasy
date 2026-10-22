#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
p2_log=$(mktemp)
p2_dir=$(mktemp -d)
trap 'rm -f "$p2_log"; rm -rf "$p2_dir"' EXIT
run_p2_script() {
  local script="$1" marker="$2"
  shift 2
  timeout 140 "${GODOT_BIN:-godot}" --headless --path client --script "res://tests/$script.gd" "$@" > "$p2_log" 2>&1 || { cat "$p2_log"; return 1; }
  cat "$p2_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$p2_log"; then return 1; fi
  rg -q "$marker: [1-9][0-9]* checks, 0 failures" "$p2_log"
}
run_p2_script item_inventory_tests 'Item inventory tests'
run_p2_script resource_foundation_tests 'Resource foundation tests'
run_p2_script p2_authority_tests 'P2 authority tests'
run_p2_script p2_persistence_tests 'P2 persistence tests'
run_p2_script p2_scenario_tests 'P2 scenario tests'
run_p2_script p2_restart_process 'P2 restart save tests' -- save "--p2-slot=$p2_dir/checkpoint.json"
run_p2_script p2_restart_process 'P2 restart resume tests' -- resume "--p2-slot=$p2_dir/checkpoint.json"
