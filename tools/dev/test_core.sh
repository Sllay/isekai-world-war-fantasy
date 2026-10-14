#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
godot_bin="${GODOT_BIN:-godot}"
core_log=$(mktemp)
trap 'rm -f "$core_log"' EXIT
run_checked() {
  "$godot_bin" "$@" >"$core_log" 2>&1 || { cat "$core_log"; return 1; }
  cat "$core_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$core_log"; then
    return 1
  fi
}
run_checked --headless --path client --editor --import --quit
run_checked --headless --path client --script res://tests/core_tests.gd
rg -q 'Core tests: [0-9]+ checks, 0 failures' "$core_log"
run_checked --headless --path client -- --core-smoke
rg -q 'runtime_started' "$core_log"
run_checked --headless --path client --quit-after 10
