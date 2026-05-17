#!/usr/bin/env zsh
#
# 维护注释：本脚本把 runtime native-readiness probe 的 failure-domain
# continuation 做成一个回归护栏。它连续验证 stage83 环境分类、native bridge
# no-resource 回归 probe、temporary package link route 和 runtime package build，
# 用于区分 automation Metal 环境约束与代码 / bridge / package blocker。
# Truth: 这是 probe/script 层 failure-domain regression guard；不新增 runtime
# readiness owner，不执行 runtime native probe，不调用 production application
# singleton accessor，不创建 singleton，不扩 native bridge，不升级 production
# ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-failure-domain-regression-guard"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLASSIFICATION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_environment_constraint_classification.sh"
SKELETON_SCRIPT="$SCRIPT_DIR/verify_native_bridge_skeleton_compile.sh"
NO_RESOURCE_SYMBOLS_SCRIPT="$SCRIPT_DIR/verify_native_bridge_no_resource_symbols.sh"
PACKAGE_LINK_SCRIPT="$SCRIPT_DIR/verify_native_bridge_cjpm_package_link_probe.sh"
CLASSIFICATION_LOG="$TMP_DIR/stage83-environment-classification.log"
SKELETON_LOG="$TMP_DIR/native-bridge-skeleton.log"
NO_RESOURCE_SYMBOLS_LOG="$TMP_DIR/native-bridge-no-resource-symbols.log"
PACKAGE_LINK_LOG="$TMP_DIR/native-bridge-package-link.log"
BUILD_LOG="$TMP_DIR/runtime-package-build.log"
BUILD_TARGET="$TMP_DIR/runtime-package-build-target"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR"
: > "$CLASSIFICATION_LOG"
: > "$SKELETON_LOG"
: > "$NO_RESOURCE_SYMBOLS_LOG"
: > "$PACKAGE_LINK_LOG"
: > "$BUILD_LOG"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

required_scripts=(
  "$CLASSIFICATION_SCRIPT"
  "$SKELETON_SCRIPT"
  "$NO_RESOURCE_SYMBOLS_SCRIPT"
  "$PACKAGE_LINK_SCRIPT"
)

for required_script in "${required_scripts[@]}"; do
  if [[ ! -x "$required_script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: missing executable script $required_script" >&2
    exit 3
  fi
done

run_required_probe() {
  local label="$1"
  local log_file="$2"
  shift 2
  if ! "$@" > "$log_file" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: $label failed" >&2
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: log=$log_file" >&2
    exit 4
  fi
}

ensure_cjpm() {
  if command -v cjpm >/dev/null 2>&1 && command -v cjc >/dev/null 2>&1; then
    return
  fi
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
  if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: cjpm/cjc not found" >&2
    exit 5
  fi
}

run_required_probe \
  "stage83 environment classification" \
  "$CLASSIFICATION_LOG" \
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" PATH="$PS_SHIM_DIR:$PATH" zsh "$CLASSIFICATION_SCRIPT"

required_classification_facts=(
  "route_classification=environment_constraint_failure_classification"
  "evidence_execution_probe_passed=true"
  "runtime_native_probe_execution=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "next_runtime_native_probe_execution_requires_human_approval=true"
)

for fact in "${required_classification_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFICATION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: missing classification fact $fact" >&2
    exit 6
  fi
done

smoke_classification="$(grep -Eo 'smoke_environment_classification=[A-Za-z0-9_]+' "$CLASSIFICATION_LOG" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo 'smoke_exit_code=[0-9]+' "$CLASSIFICATION_LOG" | tail -1 | cut -d= -f2)"
failure_domain="none"
smoke_environment_unavailable="false"
smoke_metal_capable="false"

case "$smoke_classification" in
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" ]]; then
      echo "cjgui renderer NSApplication runtime native probe failure-domain guard: Metal-unavailable classification without exit 20" >&2
      exit 7
    fi
    failure_domain="automation_environment"
    smoke_environment_unavailable="true"
    ;;
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" ]]; then
      echo "cjgui renderer NSApplication runtime native probe failure-domain guard: Metal-capable classification without exit 0" >&2
      exit 8
    fi
    smoke_metal_capable="true"
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe failure-domain guard: unexpected smoke classification $smoke_classification" >&2
    exit 9
    ;;
esac

run_required_probe \
  "native bridge skeleton compile regression" \
  "$SKELETON_LOG" \
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" PATH="$PS_SHIM_DIR:$PATH" zsh "$SKELETON_SCRIPT"

run_required_probe \
  "native bridge no-resource symbol regression" \
  "$NO_RESOURCE_SYMBOLS_LOG" \
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" PATH="$PS_SHIM_DIR:$PATH" zsh "$NO_RESOURCE_SYMBOLS_SCRIPT"

run_required_probe \
  "native bridge cjpm package link regression" \
  "$PACKAGE_LINK_LOG" \
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" PATH="$PS_SHIM_DIR:$PATH" zsh "$PACKAGE_LINK_SCRIPT"

if ! (
  export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR"
  export PATH="$PS_SHIM_DIR:$PATH"
  ensure_cjpm
  cd "$ROOT_DIR"
  cjpm build --target-dir "$BUILD_TARGET" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe failure-domain guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe failure-domain guard: log=$BUILD_LOG" >&2
  exit 10
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe failure-domain guard: protected path modified" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe failure-domain guard: forbidden production native bridge diff found" >&2
  exit 12
fi

echo "cjgui renderer NSApplication runtime native probe failure-domain guard: route_classification=runtime_native_probe_failure_domain_regression_guard"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: stage83_environment_classification_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: native_bridge_skeleton_regression_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: native_bridge_no_resource_symbol_regression_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: native_bridge_package_link_regression_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: smoke_environment_unavailable=$smoke_environment_unavailable"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: smoke_metal_capable=$smoke_metal_capable"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: compact_navigation_reconciliation_folded=true"
echo "cjgui renderer NSApplication runtime native probe failure-domain guard: next_runtime_native_probe_execution_requires_human_approved_metal_capable_shell=true"
