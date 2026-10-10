#!/usr/bin/env zsh
# 越界拖选驻留回归：指针静止在带外时，框架必须按时间继续驱动既有滚动通道；松开/取消/回到带内
# 立即停止且不补放积压。不显示窗口、不合成系统输入。
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
output_dir="${CJGUI_DRAG_EDGE_RESIDENCE_TMPDIR:-$(mktemp -d /private/tmp/cjgui-drag-edge-residence.XXXXXX)}"
mkdir -p "$output_dir"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_drag_edge_scroll_residence_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  "$runtime_dir/native/cjgui_async_multiline_measure.m" \
  "$runtime_dir/native/cjgui_async_multiline_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_drag_edge_scroll_residence_test"
"$output_dir/composable_drag_edge_scroll_residence_test"
