#!/usr/bin/env bash
# CJGUI 核心 → ohos 交叉编译探针。
#
# 把 runtime/cjgui 的仓颉源码同步进 cjgui_core_probe 模块（该目录被 .gitignore 排除，
# 不改动 runtime/cjgui 本体），用已验证的 hvigor 仓颉管线按 aarch64-linux-ohos 编译，
# 汇总"能否编译/链接"的逐文件证据。
#
# 用法： bash scripts/probe_cjgui_ohos.sh

set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

REPO_ROOT="$(cd ../.. && pwd)"
CJGUI="$REPO_ROOT/runtime/cjgui"
PROBE="cjgui_core_probe"
LOG="${PROBE_LOG:-/tmp/cjgui_ohos_probe.log}"

[ -d "$CJGUI/src" ] || { echo "找不到 cjgui 源码: $CJGUI/src"; exit 1; }

echo "== 1/4 同步源码（不改动 runtime/cjgui）=="
mkdir -p "$PROBE/src/main/cangjie" "$PROBE/shared_operation_core"
rsync -a --delete --exclude 'target' --exclude 'build' "$CJGUI/src/" "$PROBE/src/main/cangjie/"
rsync -a --delete --exclude 'target' --exclude 'build' "$CJGUI/shared_operation_core/src/" "$PROBE/shared_operation_core/src/"

# 依赖包 cjgui_shared_operation_core 的原 cjpm.toml 没有 ohos 目标段，
# 直接沿用会在链接期找不到 crti.o/-lc。这里生成带目标段的探针版清单。
cat > "$PROBE/shared_operation_core/cjpm.toml" <<'TOML'
[package]
  cjc-version = "1.1.3"
  name = "cjgui_shared_operation_core"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"

[target.aarch64-linux-ohos]
  compile-option = "-B \"${DEVECO_CANGJIE_HOME}/build-tools/third_party/llvm/bin\" -B \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/aarch64-linux-ohos\" --sysroot \"${DEVECO_OH_NATIVE_HOME}/sysroot\""
[target.aarch64-linux-ohos.bin-dependencies]
  path-option = ["${AARCH64_LIBS}", "${AARCH64_MACRO_LIBS}", "${AARCH64_KIT_LIBS}"]
  package-option = {}
TOML
echo "同步文件数: $(find "$PROBE/src/main/cangjie" "$PROBE/shared_operation_core" -name '*.cj' | wc -l | tr -d ' ')"

echo "== 2/4 编译（hvigor 仓颉管线 → aarch64-linux-ohos）=="
BUILD_EXIT=0
"$DEVECO_CLI" build --modules "$PROBE" --build-mode debug >"$LOG" 2>&1 || BUILD_EXIT=$?
echo "build exit=${BUILD_EXIT}, 日志: $LOG"

echo "== 3/4 结果归类 =="
REAL_ERR=$(grep -cE '(^|[^a-zA-Z])error(:| )' "$LOG" || true)
WARN_CNT=$(grep -cE 'warning(:| )' "$LOG" || true)
SRC_HITS=$(grep -oE '[A-Za-z0-9_/.-]+\.cj:[0-9]+' "$LOG" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')
LINK_ERR=$(grep -cE 'ld\.lld|ld64\.lld' "$LOG" || true)
echo "error 行: $REAL_ERR ; warning 行: $WARN_CNT ; 涉及 .cj 文件数(含警告): $SRC_HITS ; 链接错误行: $LINK_ERR"

echo "== 4/4 真正的 error 摘要 =="
grep -E 'error(:| )' "$LOG" | head -10 || true

if [ "$BUILD_EXIT" -eq 0 ]; then
  echo "✅ 全部通过：CJGUI 仓颉核心可按 ohos 目标编译"
else
  echo "⚠️ 未通过；完整日志见 $LOG"
fi
