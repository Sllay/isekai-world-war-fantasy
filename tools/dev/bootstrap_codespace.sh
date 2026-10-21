#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export ISEKAI_DEV_HOST="codespace"
export INSTALL_CODEX_CLI="1"
exec bash "$ROOT_DIR/tools/dev/bootstrap_dev_environment.sh"
