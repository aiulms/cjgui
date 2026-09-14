#!/usr/bin/env zsh

# Platform-free TDD probe for the Cangjie composable component/layout/scene
# path. The renderer bridge is intentionally not linked here: a failure shows
# a layout or stable-input mapping regression rather than a desktop issue.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_COMPOSABLE_UI_TMPDIR:-/private/tmp/cjgui-composable-ui-layout}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
mkdir -p "$TMP_DIR" "$PS_SHIM_DIR"
printf '#!/usr/bin/env sh\necho zsh\n' > "$PS_SHIM_DIR/ps"
chmod +x "$PS_SHIM_DIR/ps"

export PATH="$PS_SHIM_DIR:$PATH"
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
set -u

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk cjpm build --skip-script
)

SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
cjc --sysroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/probe/composable_ui_layout_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -o "$TMP_DIR/composable_ui_layout_probe"
"$TMP_DIR/composable_ui_layout_probe"
