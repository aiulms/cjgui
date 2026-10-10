#!/usr/bin/env zsh
# 跨片段高亮覆盖交接回归：transfer 只让目标片段的声明让位，其它可见片段必须继续画 owner 最后被
# 接受的声明；更新的 accepted 场景到达后整场恢复。不显示窗口、不合成系统输入。
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_DECLARED_COVERAGE_TMPDIR:-$(mktemp -d /private/tmp/cjgui-declared-coverage.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_declared_selection_coverage_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  "$runtime_dir/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_declared_selection_coverage_test"
"$output_dir/composable_declared_selection_coverage_test"
