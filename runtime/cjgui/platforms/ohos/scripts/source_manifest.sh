#!/usr/bin/env bash
# 生成最终构建输入清单：核心/应用/宿主/ArkTS/构建脚本/配置/链接桩/依赖/工具链身份。
#
# 用法： bash source_manifest.sh <LAB_ROOT> <OUT_FILE>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLATFORM/../../../.." && pwd)"
LAB="${1:?用法: source_manifest.sh <LAB_ROOT> <OUT_FILE>}"
OUT="${2:?用法: source_manifest.sh <LAB_ROOT> <OUT_FILE>}"
source "$HERE/env.sh"

# 清单记录本轮实际消费的核心 profile、冻结清单与对应宿主。调用方未显式
# 选择时与 sync/build_renderer 的默认一致（snapshot）；main 必须通过冻结
# 清单校验，否则拒绝生成一份“看似同源”的清单。
CORE_PROFILE="${CJGUI_CORE_PROFILE:-snapshot}"
case "$CORE_PROFILE" in
  main|snapshot) ;;
  *) echo "未知核心 profile: $CORE_PROFILE（只接受 main/snapshot）" >&2; exit 1 ;;
esac
if [ "$CORE_PROFILE" = "main" ]; then
  CORE_SRC="$PLATFORM/main_core/src"
  CORE_MANIFEST="$PLATFORM/main_core/MANIFEST.sha256"
  CORE_HEADER="$PLATFORM/main_core/cjgui_internal_renderer.h"
  HOST_SRC="$PLATFORM/host_main"
  (cd "$PLATFORM/main_core" && shasum -a 256 -c MANIFEST.sha256 > /dev/null) || {
    echo "冻结主树核心清单校验失败: $CORE_MANIFEST（拒绝生成清单）" >&2; exit 1; }
  CORE_MANIFEST_SHA="$(shasum -a 256 "$CORE_MANIFEST" | awk '{print $1}')"
  CORE_SOURCE_REVISION="$(head -1 "$PLATFORM/main_core/SOURCE_REVISION.txt")"
else
  CORE_SRC="$PLATFORM/snapshot/src"
  CORE_MANIFEST="none"
  CORE_HEADER="$PLATFORM/snapshot/cjgui_internal_renderer.h"
  HOST_SRC="$PLATFORM/host"
  CORE_MANIFEST_SHA="none"
  CORE_SOURCE_REVISION="none"
fi

{
  echo "# CJGUI 鸿蒙后端构建输入清单"
  echo "generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "lab=$LAB"
  echo "platform_fingerprint=$(cat "$PLATFORM/FINGERPRINT.txt" 2>/dev/null || echo missing)"
  echo "core_profile=$CORE_PROFILE"
  echo "core_source=$CORE_SRC"
  echo "core_header=$CORE_HEADER"
  echo "core_manifest=$CORE_MANIFEST"
  echo "core_manifest_sha256=$CORE_MANIFEST_SHA"
  echo "core_source_revision=$CORE_SOURCE_REVISION"
  echo "host_source=$HOST_SRC"
  if [ -n "${CJGUI_FROZEN_INPUT_MANIFEST:-}" ]; then
    echo "frozen_input_manifest=$CJGUI_FROZEN_INPUT_MANIFEST"
    shasum -a 256 "$CJGUI_FROZEN_INPUT_MANIFEST"
  fi
  echo
  echo "## 工具链身份"
  echo "deveco_studio=$DEVECO_STUDIO_HOME"
  echo "deveco_cli=$DEVECO_CLI ($(node "$DEVECO_CLI" --version 2>/dev/null | head -1 || echo unknown))"
  echo "oh_native_sdk=$DEVECO_OH_NATIVE_HOME"
  echo "cangjie_home=$DEVECO_CANGJIE_HOME"
  echo "clang=$("$DEVECO_OH_NATIVE_HOME/llvm/bin/clang++" --version 2>/dev/null | head -1)"
  echo "hdc=$HDC"
  echo
  echo "## 框架侧构建输入（平台目录；host_source=$HOST_SRC）"
  # E.3：逐项安全枚举（find -print0），含空格路径不再按空白拆分。
  find "$HOST_SRC" "$PLATFORM/scripts" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done
  echo
  echo "## 以 sha256 冻结的源码（lab 内实际参与编译者）"
  # Follow this consumer's actual local dependency graph, including transitive
  # shared packages and their compile options. A missing reachable module is
  # an error, rather than a partial freeze or an unrelated sample fallback.
  python3 "$HERE/source_inputs.py" "$LAB" | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done
  echo
  echo "## 工程与构建配置"
  find "$LAB" -maxdepth 2 \( -name '*.json5' -o -name '*.ts' -o -name 'oh-package*.json5' \) -type f -print0 \
      | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done
  for f in "$LAB/entry/src/main/module.json5" "$LAB/entry/cjpm.toml" "$LAB/entry/ohos_transport/cjpm.toml"; do
    [ -f "$f" ] && shasum -a 256 "$f"
  done
  echo
  echo "## 打包依赖（entry/libs 运行时闭包）"
  find "$LAB/entry/libs" -type f -print0 2>/dev/null | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done || true
} > "$OUT"

echo "清单已写入 ${OUT}（$(grep -c '  ' "$OUT") 项）"
