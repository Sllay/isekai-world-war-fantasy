#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
action_test_dir=$(mktemp -d)
action_test_log=$(mktemp)
trap 'rm -rf -- "$action_test_dir"; rm -f -- "$action_test_log"' EXIT
run_checked() {
  "${GODOT_BIN:-godot}" --headless --path client --script "$1" -- "${@:2}" >"$action_test_log" 2>&1 || { cat "$action_test_log"; return 1; }
  cat "$action_test_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$action_test_log"; then return 1; fi
  rg -q 'tests: [0-9]+ checks, 0 failures' "$action_test_log"
}
run_checked res://tests/combat_action_tests.gd
run_checked res://tests/combat_action_runtime_tests.gd "$action_test_dir" --combat-actions-acceptance
run_checked res://tests/combat_action_restart_process.gd save "$action_test_dir"
run_checked res://tests/combat_action_restart_process.gd resume "$action_test_dir"
# Generic Core must remain free of action/combat/player implementation references.
if rg -n 'ActionExecutor|ActionDefinition|CombatService|PlayerIntent|foundation/actions|foundation/combat' client/core; then
  echo 'Core gameplay leakage detected'
  exit 1
fi
