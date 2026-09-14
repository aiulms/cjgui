#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
zsh "$SCRIPT_DIR/build.sh"
exec python3 "$SCRIPT_DIR/test_shared_operation_second_consumer.py"
