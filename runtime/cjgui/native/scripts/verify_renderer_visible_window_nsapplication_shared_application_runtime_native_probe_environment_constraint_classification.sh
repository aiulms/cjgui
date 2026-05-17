#!/usr/bin/env zsh
#
# 维护注释：本脚本把 visible-window NSApplication shared-application
# runtime native-readiness probe evidence execution 后的自动化环境约束做成可复核
# 分类。它只重跑既有 owner-probe evidence 与 lab auto-close smoke，并把
# automation Metal unavailable / Metal-capable smoke 结果记录为 route evidence。
# Truth: 这是 probe/script 层 failure classification，不新增 readiness owner，
# 不执行 runtime native probe，不调用 production application singleton accessor，
# 不创建 singleton，不扩 native bridge，不升级 production ownership truth。
# Stop-line: 不调用 production sharedApplication accessor，不创建或激活
# NSApplication，不修改 activation policy，不运行 AppKit event loop / bounded
# pump，不执行 cleanup / teardown，不创建 visible window，不 visible order，不取
# nextDrawable，不 render / commit / present / GPU submission，不改 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-environment-classification"
EVIDENCE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_runtime_native_readiness_probe_evidence_execution.sh"
SMOKE_SCRIPT="$REPO_DIR/labs/macos_bridge_smoke/scripts/verify_auto_close.sh"
EVIDENCE_LOG="$TMP_DIR/evidence-execution.log"
SMOKE_LOG="$TMP_DIR/auto-close.log"
SMOKE_WRAPPER_LOG="$TMP_DIR/auto-close-wrapper.log"
PS_SHIM_DIR="$TMP_DIR/ps-shim"

mkdir -p "$TMP_DIR"
mkdir -p "$PS_SHIM_DIR"
: > "$EVIDENCE_LOG"
: > "$SMOKE_LOG"
: > "$SMOKE_WRAPPER_LOG"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

if [[ ! -f "$EVIDENCE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe environment classification: missing evidence script $EVIDENCE_SCRIPT" >&2
  exit 3
fi

if [[ ! -x "$SMOKE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe environment classification: missing executable smoke script $SMOKE_SCRIPT" >&2
  exit 4
fi

zsh "$EVIDENCE_SCRIPT" > "$EVIDENCE_LOG"

required_evidence_facts=(
  "route_classification=non_homogeneous_probe_evidence_execution"
  "readiness_owner_created=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "runtime_native_probe_execution=false"
  "no_singleton_creation=true"
  "production_singleton_owner_implementation=false"
  "cleanup_teardown_execution=false"
  "production_singleton_ownership_truth=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "next_runtime_native_probe_execution_requires_d3=true"
)

for fact in "${required_evidence_facts[@]}"; do
  if ! grep -F "$fact" "$EVIDENCE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe environment classification: missing evidence fact $fact" >&2
    exit 5
  fi
done

set +e
(
  export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$TMP_DIR/clang-module-cache}"
  export CJGUI_VERIFY_LOG="$SMOKE_LOG"
  export PATH="$PS_SHIM_DIR:$PATH"
  bash "$SMOKE_SCRIPT"
) > "$SMOKE_WRAPPER_LOG" 2>&1
smoke_exit_code="$?"
set -e

smoke_environment_classification=""
smoke_environment_unavailable="false"
smoke_metal_capable="false"

case "$smoke_exit_code" in
  0)
    if ! grep -F "cjgui verify: auto-close log assertions passed" "$SMOKE_WRAPPER_LOG" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe environment classification: smoke exit 0 without assertions" >&2
      echo "cjgui renderer NSApplication runtime native probe environment classification: smoke log $SMOKE_WRAPPER_LOG" >&2
      exit 6
    fi
    smoke_environment_classification="automation_smoke_metal_capable"
    smoke_metal_capable="true"
    ;;
  20)
    if ! grep -F "default Metal device is unavailable" "$SMOKE_WRAPPER_LOG" "$SMOKE_LOG" >/dev/null 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe environment classification: smoke exit 20 without Metal-unavailable evidence" >&2
      echo "cjgui renderer NSApplication runtime native probe environment classification: smoke log $SMOKE_WRAPPER_LOG" >&2
      exit 7
    fi
    smoke_environment_classification="automation_smoke_metal_unavailable"
    smoke_environment_unavailable="true"
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe environment classification: unexpected smoke exit $smoke_exit_code" >&2
    echo "cjgui renderer NSApplication runtime native probe environment classification: smoke log $SMOKE_WRAPPER_LOG" >&2
    exit "$smoke_exit_code"
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe environment classification: protected path modified" >&2
  exit 8
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe environment classification: forbidden production native bridge diff found" >&2
  exit 9
fi

echo "cjgui renderer NSApplication runtime native probe environment classification: route_classification=environment_constraint_failure_classification"
echo "cjgui renderer NSApplication runtime native probe environment classification: evidence_execution_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe environment classification: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe environment classification: smoke_environment_classification=$smoke_environment_classification"
echo "cjgui renderer NSApplication runtime native probe environment classification: smoke_environment_unavailable=$smoke_environment_unavailable"
echo "cjgui renderer NSApplication runtime native probe environment classification: smoke_metal_capable=$smoke_metal_capable"
echo "cjgui renderer NSApplication runtime native probe environment classification: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe environment classification: next_runtime_native_probe_execution_requires_human_approval=true"
