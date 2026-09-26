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

{
  echo "# CJGUI 鸿蒙后端构建输入清单"
  echo "generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "lab=$LAB"
  echo "platform_fingerprint=$(cat "$PLATFORM/FINGERPRINT.txt" 2>/dev/null || echo missing)"
  echo
  echo "## 工具链身份"
  echo "deveco_studio=$DEVECO_STUDIO_HOME"
  echo "deveco_cli=$DEVECO_CLI ($(node "$DEVECO_CLI" --version 2>/dev/null | head -1 || echo unknown))"
  echo "oh_native_sdk=$DEVECO_OH_NATIVE_HOME"
  echo "cangjie_home=$DEVECO_CANGJIE_HOME"
  echo "clang=$("$DEVECO_OH_NATIVE_HOME/llvm/bin/clang++" --version 2>/dev/null | head -1)"
  echo "hdc=$HDC"
  echo
  echo "## 框架侧构建输入（平台目录）"
  # E.3：逐项安全枚举（find -print0），含空格路径不再按空白拆分。
  find "$PLATFORM/host" "$PLATFORM/scripts" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done
  echo
  echo "## 以 sha256 冻结的源码（lab 内实际参与编译者）"
  find "$LAB/entry/cjgui/src" "$LAB/entry/shared_operation_core/src" \
      "$LAB/entry/settings_counter_application/src" "$LAB/entry/ohos_transport/src" \
      "$LAB/entry/src/main/cpp" "$LAB/entry/src/main/cangjie" "$LAB/entry/src/main/ets" \
      "$LAB/entry/src/main/resources" -type f -print0 2>/dev/null | sort -z \
      | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done || true   # 可选目录：不存在时 find 非零，不得中止整个清单
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
