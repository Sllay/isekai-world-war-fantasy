#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
enemy_test_dir=$(mktemp -d)
enemy_test_log=$(mktemp)
trap 'rm -rf -- "$enemy_test_dir"; rm -f -- "$enemy_test_log"' EXIT
run_checked() {
  timeout 90 "${GODOT_BIN:-godot}" --headless --path client --script "$1" -- "${@:2}" >"$enemy_test_log" 2>&1 || { cat "$enemy_test_log"; return 1; }
  cat "$enemy_test_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$enemy_test_log"; then return 1; fi
  rg -q 'tests: [0-9]+ checks, 0 failures' "$enemy_test_log"
}
run_checked res://tests/enemy_telegraph_tests.gd "$enemy_test_dir"
for phase in save resume cast defeated; do
  run_checked res://tests/enemy_restart_process.gd "$phase" "$enemy_test_dir"
done
if rg -n 'EnemyActor|EnemyController|Telegraph|TargetingService|foundation/(targeting|telegraphs)|gameplay/enemies' client/core; then
  echo 'Core gameplay leakage detected'
  exit 1
fi
