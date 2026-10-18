#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GODOT_VERSION="4.7.2"
TESTS=(
  core
  player
  combat
  combat_actions
  enemy_telegraphs
  world
  save_resume
)

usage() {
  cat <<'EOF'
Usage: bash tools/dev/devctl.sh <command> [args]

Commands:
  health                 Check local toolchain + Godot/MCP/LSP readiness.
  mcp-status             Check runtime MCP/LSP ports without retry loops.
  godot-check            Import/parse the Godot project headlessly.
  test all               Run all current deterministic test suites.
  test <name>            Run one suite: core, player, combat, combat_actions,
                         enemy_telegraphs, world, save_resume.
  test affected [base]   Conservative path-based affected-suite selection.
                         Defaults to git merge-base HEAD origin/main; falls back
                         to all tests when impact is uncertain.
  report                 Run health + godot-check + all tests.
EOF
}

ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; return 1; }

has_command() {
  command -v "$1" >/dev/null 2>&1
}

port_open() {
  local host="$1"
  local port="$2"
  if has_command nc; then
    nc -z "$host" "$port" >/dev/null 2>&1
  else
    return 1
  fi
}

check_health() {
  local failures=0

  [[ -f client/project.godot ]] && ok "client/project.godot present" || { fail "client/project.godot missing"; failures=$((failures + 1)); }

  if has_command godot; then
    local gv
    gv="$(godot --version 2>/dev/null || true)"
    if [[ "$gv" == "$GODOT_VERSION"* ]]; then
      ok "Godot $gv"
    else
      fail "Expected Godot $GODOT_VERSION.x-compatible project host, found '$gv'"
      failures=$((failures + 1))
    fi
  else
    fail "godot not found"
    failures=$((failures + 1))
  fi

  if has_command node; then
    local nv major
    nv="$(node --version)"
    major="$(printf '%s' "$nv" | sed -E 's/^v([0-9]+).*/\1/')"
    if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 22 )); then
      ok "Node $nv"
    else
      fail "Node 22+ required for diagnostic MCP; found $nv"
      failures=$((failures + 1))
    fi
  else
    fail "node not found"
    failures=$((failures + 1))
  fi

  has_command rg && ok "ripgrep available" || { fail "ripgrep not found"; failures=$((failures + 1)); }

  if has_command codex; then ok "Codex $(codex --version 2>/dev/null || true)"; else warn "Codex CLI not installed on this host"; fi
  if has_command serena; then ok "Serena installed"; else warn "Serena not installed; run bootstrap_codespace.sh"; fi

  if [[ -f .serena/project.yml ]]; then ok "Serena project config present"; else fail ".serena/project.yml missing"; failures=$((failures + 1)); fi
  if [[ -f .codex/config.toml ]]; then ok "Codex project config present"; else fail ".codex/config.toml missing"; failures=$((failures + 1)); fi

  if port_open 127.0.0.1 6008; then
    ok "Godot GDScript LSP reachable on 127.0.0.1:6008"
  else
    warn "Godot GDScript LSP not reachable on :6008 (Serena/minimal diagnostics will be degraded)"
  fi

  if port_open 127.0.0.1 6550; then
    ok "Godot runtime MCP bridge reachable on 127.0.0.1:6550"
  else
    warn "Godot runtime MCP bridge not reachable on :6550 (DEGRADED/STATIC mode is allowed)"
  fi

  if (( failures > 0 )); then
    printf '\nHealth finished with %d blocking problem(s).\n' "$failures" >&2
    return 1
  fi

  printf '\nHealth checks passed. MCP/LSP warnings only affect live semantic/runtime capabilities.\n'
}

mcp_status() {
  local live=0
  if port_open 127.0.0.1 6008; then ok "LSP :6008 reachable"; else warn "LSP :6008 unavailable"; live=1; fi
  if port_open 127.0.0.1 6006; then ok "DAP :6006 reachable"; else warn "DAP :6006 unavailable or no debug session"; fi
  if port_open 127.0.0.1 6550; then ok "runtime MCP :6550 reachable"; else warn "runtime MCP :6550 unavailable"; live=1; fi
  return "$live"
}

godot_check() {
  local godot_bin="${GODOT_BIN:-godot}"
  if ! command -v "$godot_bin" >/dev/null 2>&1; then
    fail "Godot executable '$godot_bin' not found"
    return 1
  fi
  local log rc=0
  log="$(mktemp)"
  "$godot_bin" --headless --path client --editor --import --quit >"$log" 2>&1 || rc=$?
  cat "$log"
  if (( rc != 0 )); then
    rm -f "$log"
    return "$rc"
  fi
  if rg -q 'SCRIPT ERROR:|ERROR:|WARNING:.*leaked|resources still in use' "$log"; then
    rm -f "$log"
    fail "Godot import/parse reported errors"
    return 1
  fi
  rm -f "$log"
  ok "Godot import/parse clean"
}

run_test() {
  local name="$1"
  local script="tools/dev/test_${name}.sh"
  if [[ ! -f "$script" ]]; then
    fail "Unknown/missing test suite '$name' ($script)"
    return 2
  fi
  printf '\n=== test:%s ===\n' "$name"
  bash "$script"
}

run_all_tests() {
  local name
  for name in "${TESTS[@]}"; do
    run_test "$name"
  done
}

unique_tests_from_diff() {
  local base="$1"
  local files
  files="$(git diff --name-only "$base"...HEAD 2>/dev/null || true)"
  if [[ -z "$files" ]]; then
    printf '%s\n' "${TESTS[@]}"
    return 0
  fi

  # Architecture/core/config changes are intentionally conservative.
  if printf '%s\n' "$files" | rg -q '^(client/core/|client/runtime/|client/project\.godot|shared/|data/|\.codex/|\.serena/|tools/dev/)'; then
    printf '%s\n' "${TESTS[@]}"
    return 0
  fi

  local selected=()
  add() {
    local candidate="$1" existing
    for existing in "${selected[@]:-}"; do [[ "$existing" == "$candidate" ]] && return 0; done
    selected+=("$candidate")
  }

  if printf '%s\n' "$files" | rg -q 'client/foundation/player/|client/.*/player|tests/player'; then add player; fi
  if printf '%s\n' "$files" | rg -q 'client/foundation/combat/|tests/combat'; then add combat; add combat_actions; add enemy_telegraphs; add save_resume; fi
  if printf '%s\n' "$files" | rg -q 'client/foundation/actions/|combat_actions'; then add combat_actions; add enemy_telegraphs; fi
  if printf '%s\n' "$files" | rg -q 'client/gameplay/enemies/|telegraph|target'; then add enemy_telegraphs; add combat; fi
  if printf '%s\n' "$files" | rg -q 'client/foundation/world/|client/gameplay/world/|tests/world'; then add world; add save_resume; fi
  if printf '%s\n' "$files" | rg -q 'save|persist|region_actor_state'; then add save_resume; fi

  if (( ${#selected[@]} == 0 )); then
    # Unknown impact must be safe rather than clever. The Project Brain in Block 2
    # will replace this conservative mapping with symbol/dependency impact data.
    printf '%s\n' "${TESTS[@]}"
  else
    printf '%s\n' "${selected[@]}"
  fi
}

run_affected_tests() {
  local base="${1:-}"
  if [[ -z "$base" ]]; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      base="$(git merge-base HEAD origin/main)"
    elif git rev-parse --verify main >/dev/null 2>&1; then
      base="$(git merge-base HEAD main)"
    else
      warn "Could not resolve comparison base; running all tests"
      run_all_tests
      return
    fi
  fi

  printf 'Affected-test base: %s\n' "$base"
  mapfile -t selected < <(unique_tests_from_diff "$base")
  printf 'Selected suites: %s\n' "${selected[*]}"
  local name
  for name in "${selected[@]}"; do run_test "$name"; done
}

command="${1:-}"
case "$command" in
  health)
    check_health
    ;;
  mcp-status)
    mcp_status
    ;;
  godot-check)
    godot_check
    ;;
  test)
    target="${2:-}"
    case "$target" in
      all) run_all_tests ;;
      affected) run_affected_tests "${3:-}" ;;
      "") usage; exit 2 ;;
      *) run_test "$target" ;;
    esac
    ;;
  report)
    check_health
    godot_check
    run_all_tests
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
