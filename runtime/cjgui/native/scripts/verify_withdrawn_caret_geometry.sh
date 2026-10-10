#!/usr/bin/env zsh
# 撤回声明后的 caret 几何回归：产品正文是 presentation TEXT 节点，可以换行成多条视觉行；
# 声明撤回后框架必须给出**一条视觉行**高的 caret，而不是整个节点框高。不显示窗口、不合成输入。
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_WITHDRAWN_CARET_TMPDIR:-$(mktemp -d /private/tmp/cjgui-withdrawn-caret.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_withdrawn_caret_geometry_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  "$runtime_dir/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_withdrawn_caret_geometry_test"
"$output_dir/composable_withdrawn_caret_geometry_test"
