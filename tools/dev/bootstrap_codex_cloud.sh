#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export ISEKAI_DEV_HOST="codex-cloud"
# Codex Cloud already supplies the agent runtime; the project bootstrap only
# needs project tooling/MCP dependencies inside the task environment.
export INSTALL_CODEX_CLI="0"
exec bash "$ROOT_DIR/tools/dev/bootstrap_dev_environment.sh"
