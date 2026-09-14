#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
zsh "$SCRIPT_DIR/build.sh"
exec python3 "$SCRIPT_DIR/test_backup_rule_config_consumer.py"
