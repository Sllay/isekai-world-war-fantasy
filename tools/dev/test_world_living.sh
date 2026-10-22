#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
p3_log=$(mktemp)
p3_dir=$(mktemp -d)
trap 'rm -f "$p3_log"; rm -rf "$p3_dir"' EXIT
run_p3() {
  local script="$1" marker="$2"
  shift 2
  timeout 160 "${GODOT_BIN:-godot}" --headless --path client --script "res://tests/$script.gd" "$@" > "$p3_log" 2>&1 || { cat "$p3_log"; return 1; }
  cat "$p3_log"
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$p3_log"; then return 1; fi
  rg -q "$marker: [1-9][0-9]* checks, 0 failures" "$p3_log"
}
for pair in 'worldgen|world generation' 'chunk|chunk lifecycle' 'streaming|streaming' 'rpg|RPG' 'perception|perception' 'lod|LOD' 'bot_authority|Bot authority' 'actor_materialization|actor materialization' 'save_pages|save pages' 'persistence|persistence'; do
  run_p3 "p3_${pair%%|*}_tests" "P3 ${pair#*|} tests"
done
for attempt in 1 2; do
  "${GODOT_BIN:-godot}" --headless --path client --script res://tests/p3_worldgen_tests.gd -- --hash-only > "$p3_dir/hash-$attempt.log" 2>&1
  cat "$p3_dir/hash-$attempt.log"
  rg '^P3_DETERMINISM_PROOF ' "$p3_dir/hash-$attempt.log" > "$p3_dir/hash-$attempt.json"
done
cmp "$p3_dir/hash-1.json" "$p3_dir/hash-2.json"
run_p3 p3_scenario_tests 'P3 semantic scenario tests'
run_p3 p3_restart_process 'P3 fresh-process save tests' -- save "--p3-slot=$p3_dir/checkpoint.json"
run_p3 p3_restart_process 'P3 fresh-process resume tests' -- resume "--p3-slot=$p3_dir/checkpoint.json"
