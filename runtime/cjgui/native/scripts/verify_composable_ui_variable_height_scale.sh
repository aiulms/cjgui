#!/usr/bin/env zsh

# Compile and run the platform-free variable-height collection scale probe.
# The probe uses ordinary Cangjie text measurement and reports 30 samples per
# scale/case; no native renderer or domain owner is substituted here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_VARIABLE_HEIGHT_SCALE_TMPDIR:-/private/tmp/cjgui-variable-height-scale}"
mkdir -p "$TMP_DIR"

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk cjpm build --skip-script
)

SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
cjc --sysroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/probe/composable_ui_variable_height_scale_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -o "$TMP_DIR/composable_ui_variable_height_scale_probe"
"$TMP_DIR/composable_ui_variable_height_scale_probe"
