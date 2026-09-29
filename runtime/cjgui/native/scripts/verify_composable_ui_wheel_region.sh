#!/usr/bin/env zsh
# B(2026-09-28) 透明滚轮列窗口级消费验收：普通容器声明 wheelScrollable 后
# 由框架按已接受几何路由滚轮，资格/位移/裁剪变化更新 accepted 输入投影，
# 撞号候选保持旧事实。
#
# 消费者 = probe/composable_ui_wheel_region_probe.cj（独立普通消费者，不依赖
# 产品与 Markdown）。它用真实窗口 + native 只读钩子断言 7 组事实，逐组打印
# CJGUI_WHEEL_REGION_* 行；本脚本按行校验（缺行即失败，不只 grep 一个布尔）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_WHEEL_REGION_TMPDIR:-/private/tmp/cjgui-wheel-region}"
mkdir -p "$OUTPUT_DIR/native"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_wheel_region.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/composable_ui_wheel_region_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_wheel_region \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_wheel_region_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
( cd "$RUNTIME_DIR/resources" && "$OUTPUT_DIR/composable_ui_wheel_region_probe" ) | tee "$OUTPUT_DIR/probe.log"

grep -q '^CJGUI_WHEEL_REGION_BASELINE .*geometry=true owner_none=true$' "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_ELIGIBLE .*is_scroll_area=0 wheel=1 .*restaged=true owner_ok=true$' "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_MOVED .*new_owner=2 old_owner=0 .*restaged=true moved=true sibling_kept=true new_ok=true old_quiet=true$' \
  "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_CLIPPED .*clip_height=120 inside=2 outside=0 .*restaged=true clip_ok=true inside_ok=true outside_quiet=true$' \
  "$OUTPUT_DIR/probe.log"
grep -q "^CJGUI_WHEEL_REGION_REFUSED reason='duplicate_node_id' .*owner=2 kept=true\$" "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_IDLE .*quiet=true$' "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_DISPATCH .*last_node=2 .*events=1 .*sibling_quiet=true$' "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_WHEEL_REGION_PROBE passed=true$' "$OUTPUT_DIR/probe.log"
echo "PASSED composable ui wheel region output=$OUTPUT_DIR"
