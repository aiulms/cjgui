#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_TWO_WINDOW_TMPDIR:-/private/tmp/cjgui-two-window-workload}"

set +u
source "/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"

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
ar rcs "$OUTPUT_DIR/native/libcjgui_two_window.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/two_window_workload_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_two_window \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/two_window_workload_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
( cd "$RUNTIME_DIR/resources" && "$OUTPUT_DIR/two_window_workload_probe" ) | tee "$OUTPUT_DIR/probe.log"
for mode in recolor image geometry; do
  grep -q "^CJGUI_TWO_WINDOW_LOCAL mode=${mode} .*in_flight_samples=20 .*passed=true$" "$OUTPUT_DIR/probe.log"
done
# F-D:显示缩放切换与 B 的识别编辑真实重叠 —— 20 个样本都要有真实的 scale/drawable 变化,
# 且缩放专用重建(rebuilt)证明稀疏复用守卫没有跳过"合法失效必须重建"。
samples=$(grep -c '^CJGUI_TWO_WINDOW_SCALE_SAMPLE ' "$OUTPUT_DIR/probe.log")
[ "$samples" -eq 20 ]
grep -q '^CJGUI_TWO_WINDOW_SCALE samples=20 .*rebuilt_all=true .*scale_rebuild=true .*all_applied=true .*passed=true$' \
  "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_TWO_WINDOW_SCALE_REBUILD .*rebuilt=true$' "$OUTPUT_DIR/probe.log"
grep -q '^CJGUI_TWO_WINDOW_WORKLOAD_PROBE passed=true$' "$OUTPUT_DIR/probe.log"
echo "PASSED two window workload output=$OUTPUT_DIR"
