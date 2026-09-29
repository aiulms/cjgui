#!/usr/bin/env zsh

# 1b 正常窗口消费链验证:平台输入服务 → 窗口 FIFO → 窗口拥有的 CjguiTextSession →
# 有界镜像 → 唯一 owner Sink。与 verify_composable_ui_range_edit.sh 同一套构建方式;
# range_text.cj 与 text_session.cj 已在共享源闭包里(窗口自身依赖会话),不再单列。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" true)}")
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_TEXT_SESSION_PROBE_TMPDIR:-/private/tmp/cjgui-text-session-probe}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui text session probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
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
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min="12.0" \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_text_session_probe.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/composable_ui_text_session_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_text_session_probe \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_text_session_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
if [[ $# -gt 0 ]]; then
  echo "usage: $0" >&2
  exit 2
fi
"$OUTPUT_DIR/composable_ui_text_session_probe"
