#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_DIR="$ROOT_DIR/.codex-local"
MODE_FILE="$LOCAL_DIR/codex-cloud-mode"
mkdir -p "$LOCAL_DIR"

# A published environment snapshot stores installed tools/files, not a promise
# that setup-time background services remain alive in future tasks.
printf 'DEGRADED\n' > "$MODE_FILE"

bash "$ROOT_DIR/tools/dev/bootstrap_codex_cloud.sh"

# Prove that the reusable filesystem is useful before publishing it.
bash "$ROOT_DIR/tools/dev/devctl.sh godot-check"
bash "$ROOT_DIR/tools/dev/devctl.sh test all"

cat <<'EOF'
Codex Cloud installation preparation complete.
Reusable state: tools installed, Godot headless validated, deterministic tests passed.
Live FULL services are intentionally started by the environment Start skill with:
  bash tools/dev/start_codex_cloud_full.sh
EOF
