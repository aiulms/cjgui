#!/usr/bin/env bash
# 计算并写入 CJGUI 鸿蒙平台指纹。
#
# 覆盖范围（构建输入的真实并集，不是只冻结核心）：
#   snapshot/src                核心仓颉源码
#   主树 shared_operation_core/src（与 sync_platform.sh 同源绑定）
#   snapshot/cjgui_internal_renderer.h   共享 ABI 头
#   host/                       宿主 + 桥 + 渲染器 + 链接桩 + CMakeLists
#
# 用法： bash scripts/fingerprint.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"

OUT="$PLATFORM/FINGERPRINT.txt"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cd "$PLATFORM"
{
  # 共享操作核心与 sync_platform.sh 同源绑定：主树共同模块（或显式覆盖）。
  SHARED_CORE_SRC="${CJGUI_SHARED_CORE_SRC:-$PLATFORM/../../shared_operation_core/src}"
  find snapshot/src "$SHARED_CORE_SRC" -type f -name '*.cj' | sort
  echo snapshot/cjgui_internal_renderer.h
  find host -type f | sort
} | while read -r f; do
  shasum -a 256 "$f"
done > "$TMP"

FINGERPRINT="$(shasum -a 256 "$TMP" | awk '{print $1}')"
echo "$FINGERPRINT" > "$OUT"
echo "$FINGERPRINT"
