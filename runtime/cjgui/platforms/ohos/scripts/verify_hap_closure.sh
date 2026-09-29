#!/usr/bin/env bash
# 用 HAP 内实际 ELF 的 NEEDED 闭包 + 明确系统库白名单校验依赖完整性。
#
# 与旧实现（对 unzip 列表做子串匹配、硬编码库名、报 9/9 却只列 8 个）的区别：
#  1) ZIP 条目按 libs/<abi>/<basename> 精确匹配，不做子串包含判断；
#  2) 必需集合从 HAP 内 .so 的真实 NEEDED 得出，不靠人工列举；
#  3) 系统提供库用显式白名单，规则与 package_runtime_libs.sh 的「跳过」分支同口径；
#  4) 应用自身产物单独断言，缺一即失败。
#
# 实现方式：不解包整个 libs 目录（旧实现 unzip 出 33 个 .so 再 rm -rf 整棵树，
# 单次执行就产生 ~35 次删除操作，会触发工作区的批量删除保护）。这里改成
# 「读条目名 + 逐个 unzip -p 流式写入同一个临时文件」，删除目标恒为 2 个文件。
#
# 可移植性（实测要求）：必须在 macOS 自带 bash 3.2 下运行——`bash xxx.sh` 默认
# 解析到 /bin/bash 3.2。因此：
#   - 不用 `declare -A` / mapfile 等 bash 4+ 特性，集合用「每行一项的临时文件
#     + grep -qxF」表示；
#   - 变量后紧跟中文/全角字符时一律写 `${var}`（bash 3.2 在 UTF-8 locale 下会把
#     全角字符的首字节并入变量名，导致 unbound variable）。
#
# 用法： bash verify_hap_closure.sh <HAP> [out_report.txt]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"

HAP="${1:?用法: verify_hap_closure.sh <HAP> [report]}"
REPORT="${2:-}"
ABI="arm64-v8a"
READOBJ="$DEVECO_OH_NATIVE_HOME/llvm/bin/llvm-readobj"

[ -f "$HAP" ] || { echo "未找到 HAP: $HAP"; exit 1; }

# 输出：有报告文件时同时落盘；否则只写 stdout。
emit() {
  if [ -n "$REPORT" ]; then
    printf '%s\n' "$1" | tee -a "$REPORT"
  else
    printf '%s\n' "$1"
  fi
}

# 系统提供（本机模拟器镜像 + 系统运行时）：不要求 HAP 自包含。
# 规则与 package_runtime_libs.sh 的「跳过（系统提供）」分支保持同一口径：
# 那边跳过什么，这边就必须白名单什么，否则会出现「打包时不复制、校验时又
# 要求存在」的假 FAIL（实测踩到：libcangjie-runtime.so -> libhitrace_ndk.z.so）。
is_system_lib() {
  local name="$1"
  case "$name" in
    libc.so|libc++_shared.so|libm.so|libdl.so|ld-musl-aarch64.so*) return 0 ;;
    libEGL.so|libGLESv3.so) return 0 ;;
    libhilog.so|libhilog_ndk.z.so) return 0 ;;
    libhitrace.so|libhitrace_ndk.z.so) return 0 ;;
    libace_napi.z.so|libace_ndk.z.so) return 0 ;;
    libnative_drawing.so|libnative_window.so|libimage_source.so|libpixelmap.so) return 0 ;;
    # libohos.*.so 由系统 ArkTS 运行时提供（SDK 内是编译桩，入包会遮蔽真身）。
    libohos.*.so) return 0 ;;
  esac
  return 1
}

# 应用自身必须产出的库（入口、核心、共享操作核心、应用、传输）。
# 应用包名可变（第六次复核第 5 项：独立消费者），由 CJGUI_APP_PKG_LIB
# 指定 lib<包名>.so；默认仍是设置计数示例。
APP_PKG_LIB="${CJGUI_APP_PKG_LIB:-libcjgui_settings_counter_application.so}"
OWN_LIBS=(
  libentry.so libcjgui_app.so libcjgui.so
  libcjgui_shared_operation_core.so "${APP_PKG_LIB}"
  libcjgui_ohos_transport.so
)

# 负对照注入点：追加要求的库名（用于验证「缺库必须失败」这条闸门本身有效）。
if [ -n "${CJGUI_EXTRA_REQUIRED_LIBS:-}" ]; then
  for extra in $CJGUI_EXTRA_REQUIRED_LIBS; do
    OWN_LIBS+=("$extra")
  done
  echo "负对照：额外要求库 ${CJGUI_EXTRA_REQUIRED_LIBS}"
fi

SCRATCH="$(mktemp -d)"
CURRENT="$SCRATCH/current.so"
MEMBER_LIST="$SCRATCH/members.txt"
PRESENT_FILE="$SCRATCH/present.txt"
trap 'rm -f "$CURRENT" "$MEMBER_LIST" "$PRESENT_FILE"; rmdir "$SCRATCH" 2>/dev/null || true' EXIT

unzip -Z1 "$HAP" "libs/${ABI}/*.so" > "$MEMBER_LIST" 2>/dev/null \
  || { echo "无法读取 HAP 成员列表（ZIP 损坏或不是 HAP）: $HAP"; exit 1; }
if [ ! -s "$MEMBER_LIST" ]; then
  echo "HAP 内没有 libs/${ABI}/*.so"
  exit 1
fi
while IFS= read -r member; do
  [ -n "$member" ] || continue
  basename "$member"
done < "$MEMBER_LIST" > "$PRESENT_FILE"
PRESENT_COUNT="$(wc -l < "$PRESENT_FILE" | tr -d ' ')"
present_contains() { grep -qxF "$1" "$PRESENT_FILE" 2>/dev/null; }

emit "HAP: $HAP"
emit "sha256: $(shasum -a 256 "$HAP" | awk '{print $1}')"
emit "HAP 内 libs/${ABI} 库数: ${PRESENT_COUNT}"
emit ""
emit "== 应用自身产物 =="

FAIL=0
for lib in "${OWN_LIBS[@]}"; do
  if present_contains "$lib"; then
    emit "  OK   $lib"
  else
    emit "  MISS $lib"
    FAIL=1
  fi
done

emit ""
emit "== 闭包校验（每个 HAP 内 .so 的每条 NEEDED 必须自包含或属系统白名单）=="

UNSAT=0
NEEDED_FILE="$SCRATCH/needed.txt"
while IFS= read -r member; do
  [ -n "$member" ] || continue
  base="$(basename "$member")"
  # 流式取出单个成员到复用路径（覆盖写，不产生删除操作）。
  # E 返工：提取失败不得 continue 跳过——损坏成员必须直接判失败。
  if ! unzip -p "$HAP" "$member" > "$CURRENT" 2>/dev/null; then
    emit "  BROKEN 成员提取失败（ZIP 内损坏）: $member"
    UNSAT=1
    continue
  fi
  # E 返工：ELF 解析不得藏在 process substitution 里静默吞错。readobj 失败
  # 或输出缺 ELF 结构标记（Format:/NeededLibraries）都按 BROKEN 拒绝。
  # 注意：NDK 的 static-pie 系统 stub 可以合法地没有任何 NEEDED——空列表
  # 不是解析失败，只是无依赖可查（实测踩到 libEGL.so/libGLESv3.so）。
  # E.5：目标 ELF 架构必须匹配设备 ABI；LoadName（SONAME 语义）必须与
  # 成员名一致——防「错误架构/改名混入」绕过依赖闭包。
  if ! "$READOBJ" --needed-libs "$CURRENT" > "$NEEDED_FILE" 2>/dev/null \
     || ! grep -q '^Format: ' "$NEEDED_FILE" \
     || ! grep -q '^NeededLibraries \[$' "$NEEDED_FILE"; then
    emit "  BROKEN ELF 解析失败（非 ELF 或 readobj 失败）: $base"
    UNSAT=1
    continue
  fi
  if ! grep -q '^Arch: aarch64$' "$NEEDED_FILE"; then
    emit "  BROKEN ELF 架构不是 aarch64: $base"
    UNSAT=1
    continue
  fi
  # 无 SONAME（readobj 报 <Not found>）合法：动态链接器按文件名解析。
  # 只有 SONAME **存在且与成员名不同**才判身份不一致。
  # 已知例外（打包决策，见 package_runtime_libs.sh）：libc++.so 在 SDK 内是
  # linker script，打包用 libc++_shared.so 实体顶替，其实体 SONAME 仍为
  # libc++_shared.so——运行期解析一致，不判 BROKEN。
  load_name="$(grep '^LoadName: ' "$NEEDED_FILE" | head -1 | sed 's/^LoadName: //' | tr -d '\r')"
  if [ -n "$load_name" ] && [ "$load_name" != "<Not found>" ] && [ "$load_name" != "$base" ]; then
    if [ "$base" = "libc++.so" ] && [ "$load_name" = "libc++_shared.so" ]; then
      :   # 已记录的顶替例外
    else
      emit "  BROKEN LoadName 与成员名不一致（${load_name} != ${base}）"
      UNSAT=1
      continue
    fi
  fi
  while read -r dep; do
    [ -n "$dep" ] || continue
    if present_contains "$dep"; then continue; fi
    if is_system_lib "$dep"; then continue; fi
    emit "  UNSAT ${base} -> ${dep} (既不在 HAP 也未列入系统白名单)"
    UNSAT=1
  # E.5：NEEDED 解析覆盖全部实际条目（不限于 lib*.so，含 ld-musl…so.1 形态）。
  done < <(awk '/^  [A-Za-z0-9_.+\-]+\.so(\.[0-9]+)?$/{print $1}' "$NEEDED_FILE")
done < "$MEMBER_LIST"

if [ "$UNSAT" = "0" ]; then
  emit "  依赖闭包完整（自包含 + 系统白名单成立）"
else
  FAIL=1
fi

# These NDK libraries are linked at build time and resolved from the target
# system at runtime. A packaged SDK link stub can mask the real implementation.
for system_link_lib in libnative_window.so libnative_drawing.so libimage_source.so libpixelmap.so; do
  if present_contains "$system_link_lib"; then
    emit "  PRODUCT-FAIL HAP 携带 ${system_link_lib}，遮蔽系统运行库"
    FAIL=1
  else
    emit "  OK   HAP 不携带 ${system_link_lib}（运行时仍需核对系统符号来源）"
  fi
done

# Cangjie SDK's libohos.*.so files are link-time mocks. They may satisfy every
# NEEDED entry in a HAP and still shadow the device's real ArkTS implementation.
while IFS= read -r packaged_lib; do
  case "$packaged_lib" in
    libohos.*.so)
      emit "  PRODUCT-FAIL HAP 携带 ${packaged_lib}，遮蔽系统运行库"
      FAIL=1 ;;
  esac
done < "$PRESENT_FILE"

emit ""
if [ "$FAIL" = "0" ]; then
  emit "RESULT: PASS"
else
  emit "RESULT: FAIL"
fi
exit "$FAIL"
