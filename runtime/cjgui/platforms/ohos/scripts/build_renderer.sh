#!/usr/bin/env bash
# 用 OHOS NDK clang 把框架拥有的宿主渲染器编译成静态库，供 cjpm 在链接
# libcjgui_app.so 时并入（实现 cjgui_internal_renderer_* ABI）。
#
# 用法： bash build_renderer.sh <LAB_ROOT> [--test-gates]
#   --test-gates 额外定义 CJGUI_OHOS_TEST_GATES，编出带受控闸门的测试变体
#                （同一生产源码，只有时序闸门被启用；用于生命周期反例）。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLATFORM/../../../.." && pwd)"
LAB="${1:-$REPO_ROOT/labs/ohos_cjgui_app}"
shift || true

TEST_GATES=0
for arg in "$@"; do
  if [ "$arg" = "--test-gates" ]; then TEST_GATES=1; fi
done

source "$HERE/env.sh"

CLANG="$DEVECO_OH_NATIVE_HOME/llvm/bin/clang++"
CC="$DEVECO_OH_NATIVE_HOME/llvm/bin/clang"
AR="$DEVECO_OH_NATIVE_HOME/llvm/bin/llvm-ar"
OUT_DIR="$LAB/entry/oh_renderer"
OUT_LIB="$OUT_DIR/libcjgui_ohos_renderer.a"
SRC="$PLATFORM/host"

mkdir -p "$OUT_DIR"

GATE_FLAG=""
if [ "$TEST_GATES" = "1" ]; then
  GATE_FLAG="-DCJGUI_OHOS_TEST_GATES"
  echo "测试闸门变体：-DCJGUI_OHOS_TEST_GATES"
fi

"$CLANG" --target=aarch64-linux-ohos \
  --sysroot="$DEVECO_OH_NATIVE_HOME/sysroot" \
  -I "$SRC" \
  -I "$PLATFORM/snapshot" \
  -I "$REPO_ROOT/runtime/cjgui/native" \
  -D__MUSL__ $GATE_FLAG \
  -O2 -fPIC -ffunction-sections -fdata-sections \
  -std=c++17 \
  -c "$SRC/ohos_renderer.cpp" \
  -o "$OUT_DIR/ohos_renderer.o"

"$CC" --target=aarch64-linux-ohos --sysroot="$DEVECO_OH_NATIVE_HOME/sysroot" -O2 -fPIC \
  -c "$SRC/ohos_bridge_link_stubs.c" -o "$OUT_DIR/ohos_bridge_link_stubs.o"

# ar 到临时库再按内容决定是否替换：内容不变时保持旧 mtime——否则每次
# 构建都让 hvigor 认为 native 输入变化而全量清重建（并触发批量删除保护）。
"$AR" rcs "$OUT_LIB.tmp" "$OUT_DIR/ohos_renderer.o" "$OUT_DIR/ohos_bridge_link_stubs.o"
if [ -f "$OUT_LIB" ] && cmp -s "$OUT_LIB.tmp" "$OUT_LIB"; then
  rm -f "$OUT_LIB.tmp"
  echo "renderer static lib unchanged: $OUT_LIB ($(du -h "$OUT_LIB" | cut -f1))"
else
  mv -f "$OUT_LIB.tmp" "$OUT_LIB"
  echo "renderer static lib: $OUT_LIB ($(du -h "$OUT_LIB" | cut -f1))"
fi
