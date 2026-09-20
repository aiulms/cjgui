#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROBE="$RUNTIME_DIR/probe/composable_ui_interaction_style_value_probe.cj"
SOURCE="$RUNTIME_DIR/src/composable_ui.cj"
OUTPUT_DIR="${CJGUI_INTERACTION_STYLE_VALUE_TMPDIR:-/private/tmp/cjgui-interaction-style-values}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  cjpm build --skip-script
)

cjc \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$SOURCE" "$PROBE" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -o "$OUTPUT_DIR/interaction_style_value_probe" \
  >"$OUTPUT_DIR/compile.log" 2>&1
"$OUTPUT_DIR/interaction_style_value_probe" >"$OUTPUT_DIR/result" 2>&1
cat "$OUTPUT_DIR/result"
print -- "CJGUI_INTERACTION_STYLE_VALUE_VERIFY source=1 probe=1 platform_free=1"
