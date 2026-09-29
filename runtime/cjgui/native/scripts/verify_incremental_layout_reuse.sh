#!/usr/bin/env zsh

# Fixed-binary, platform-free verification for cross-pass layout reuse. Native
# COW and Metal submission are intentionally covered by the normal-app runner,
# not relabelled as layout work here. The sampler invokes one binary once and
# interleaves default/full signatures with opt-in reuse in that same process.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_INCREMENTAL_LAYOUT_TMPDIR:-/private/tmp/cjgui-incremental-layout-reuse}"
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
  "$RUNTIME_DIR/src/composable_ui_named_style.cj" \
  "$RUNTIME_DIR/probe/composable_ui_layout_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -o "$TMP_DIR/composable_ui_incremental_layout_probe"

python3 "$SCRIPT_DIR/incremental_layout_reuse_report.py" \
  --binary "$TMP_DIR/composable_ui_incremental_layout_probe" \
  --samples 30 \
  --output "$TMP_DIR/incremental-layout-reuse-report.json"
printf 'CJGUI_INCREMENTAL_LAYOUT_REPORT=%s\n' "$TMP_DIR/incremental-layout-reuse-report.json"
