#!/usr/bin/env bash
# 计算并打包仓颉运行时库闭包进 <LAB>/entry/libs/arm64-v8a/。
#
# 用法： bash package_runtime_libs.sh <LAB_ROOT>
#
# 背景：本机仓颉 SDK 是经插件分发的 escape/beta SDK，hvigor 插件对
# compatibleSdkVersion>=23 的应用不自动复制 cangjie 运行时库（期望系统提供；
# 模拟器镜像实测不提供 libohos.ark_interop.so）。为保证 HAP 自包含且可复现，
# 这里按 NEEDED 闭包从 SDK 显式复制。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLATFORM/../../../.." && pwd)"
LAB="${1:-$REPO_ROOT/labs/ohos_cjgui_app}"
source "$HERE/env.sh"

ABI=arm64-v8a
OUT="$LAB/entry/libs/$ABI"
BUILD_LIBS="$LAB/entry/build/default/intermediates/libs/default/$ABI"
SDK_OHOS_LIB="$DEVECO_CANGJIE_HOME/api/lib/linux_ohos_aarch64_cjnative/ohos"
SDK_RUNTIME="$DEVECO_CANGJIE_HOME/build-tools/runtime/lib/linux_ohos_aarch64_cjnative"
SYSROOT_LIB="$DEVECO_OH_NATIVE_HOME/sysroot/usr/lib/$ABI"
READOBJ="$DEVECO_OH_NATIVE_HOME/llvm/bin/llvm-readobj"

mkdir -p "$OUT"

# 参与闭包的搜索目录；libboundscheck.so/libc++.so 模拟器镜像不提供，从 NDK 补齐。
# 注意：SDK 的 libohos.*.so 是编译期 mock 桩（14KB，无真实导出），真实实现在
# 系统 ArkTS 运行时中，不得打包进 HAP（否则遮蔽系统真身导致重定位失败）。
search_dirs=("$SDK_RUNTIME" "$DEVECO_OH_NATIVE_HOME/sysroot/usr/lib/aarch64-linux-ohos" "$DEVECO_OH_NATIVE_HOME/llvm/lib/aarch64-linux-ohos")

wanted()
{
  local lib="$1"
  for d in "${search_dirs[@]}"; do
    if [ -f "$d/$lib" ]; then
      echo "$d/$lib"
      return 0
    fi
  done
  return 1
}

declare -a queue=()
seen_file="$(mktemp)"
trap 'rm -f "$seen_file"' EXIT
seen_contains() { grep -qxF "$1" "$seen_file" 2>/dev/null; }
seen_add() { echo "$1" >> "$seen_file"; }

# 种子：模块产物目录中的全部 .so
for f in "$BUILD_LIBS"/*.so; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  # 产物本身不复制（hvigor 已打包），只解析其 NEEDED
  deps=$("$READOBJ" --needed-libs "$f" 2>/dev/null | awk '/^  lib.*\.so$/{print $1}') || true
  for d in $deps; do
    if ! seen_contains "$d"; then seen_add "$d"; queue+=("$d"); fi
  done
done

copied=0
idx=0
while [ $idx -lt ${#queue[@]} ]; do
  lib=${queue[$idx]}
  idx=$((idx+1))
  case "$lib" in
    libc.so|libc++_shared.so|libm.so|libdl.so|libhilog.so|ld-musl-aarch64.so*|*libace_napi*|*libace_ndk*|*libhilog_ndk*|*libhitrace*|libohos.*.so)
      continue ;;  # 系统提供
    libnative_window.so)
      # 引用契约（第六次复核/Sol Q3）：sysroot 的该文件是链接 shim（三符号
      # 别名 bare-ret）。真机打包（CJGUI_DEVICE_PACKAGING=1）必须跳过——
      # 平台提供真实现，打包会遮蔽平台库；模拟器镜像无平台实现，不打包则
      # NEEDED 解析失败、应用无法启动，故模拟器产物允许打包并在运行时被
      # dladdr 判定为 KnownShimNoRef（引用能力不可用，绝不虚记引用成功）。
      if [ "${CJGUI_DEVICE_PACKAGING:-0}" = "1" ]; then
        echo "跳过（真机打包禁止携带链接 shim）: $lib"
        continue
      fi
      echo "警告：打包 ${lib} sysroot shim（仅限模拟器变体，KnownShimNoRef）"
      ;;
  esac
  src=$(wanted "$lib") || { echo "跳过（非 SDK 提供）: $lib"; continue; }
  if [ ! -f "$OUT/$lib" ]; then
    cp "$src" "$OUT/$lib"
    copied=$((copied+1))
  fi
  deps=$("$READOBJ" --needed-libs "$src" 2>/dev/null | awk '/^  lib.*\.so$/{print $1}') || true
  for d in $deps; do
    if ! seen_contains "$d"; then seen_add "$d"; queue+=("$d"); fi
  done
done

# sysroot 的 libc++.so 是 linker script；用实体 libc++_shared.so 顶替该文件名
if [ -f "$OUT/libc++.so" ] && [ "$(stat -f %z "$OUT/libc++.so")" -lt 256 ]; then
  cp "$DEVECO_OH_NATIVE_HOME/llvm/lib/aarch64-linux-ohos/libc++_shared.so" "$OUT/libc++.so"
  echo "libc++.so 已替换为 libc++_shared.so 实体"
fi

echo "复制 $copied 个运行时库到 $OUT:"
ls "$OUT"
