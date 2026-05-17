#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness non-D3 recovery 的
# source/build/probe evidence route。它串联 source owner probe、stage86 recovery
# aggregation guard 与 runtime package build，并产出 script-managed evidence packet。
# Truth: 这是 source/build/probe evidence strengthening guard；不执行 runtime
# native probe，不调用 application singleton accessor，不创建 singleton，不扩 native
# bridge，不消费 human approval，不升级 production ownership truth。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-source-build-probe-evidence"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
BUILD_TARGET_DIR="$TMP_DIR/cjpm-build"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_owner.sh"
AGGREGATION_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_recovery_guard_aggregation.sh"
OWNER_PROBE_LOG="$TMP_DIR/source-build-probe-owner.log"
AGGREGATION_LOG="$TMP_DIR/recovery-aggregation.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
EVIDENCE_PACKET="$TMP_DIR/source-build-probe-evidence.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_PROBE_LOG"
: > "$AGGREGATION_LOG"
: > "$BUILD_LOG"
: > "$EVIDENCE_PACKET"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

if [[ ! -x "$OWNER_PROBE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing executable owner probe $OWNER_PROBE" >&2
  exit 3
fi
if [[ ! -x "$AGGREGATION_GUARD" ]]; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing executable aggregation guard $AGGREGATION_GUARD" >&2
  exit 4
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: this script does not consume D3 runtime native probe approval" >&2
  exit 5
fi

ensure_toolchain() {
  if command -v cjpm >/dev/null 2>&1 && command -v cjc >/dev/null 2>&1; then
    return
  fi
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    export PATH="$PS_SHIM_DIR:$PATH"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
}

ensure_toolchain

if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: cjpm unavailable" >&2
  exit 6
fi
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: cjc unavailable" >&2
  exit 7
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_PROBE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: log=$OWNER_PROBE_LOG" >&2
  exit 8
fi

required_owner_facts=(
  "runtime_native_probe_source_build_probe_evidence_owner_present=true"
  "closure_completion_input=true"
  "source_build_probe_evidence_strengthening_route=true"
  "focused_owner_probe_required=true"
  "runtime_package_build_probe_required=true"
  "recovery_aggregation_guard_required=true"
  "failure_domain_matrix_probe_required=true"
  "focused_regression_suite_required=true"
  "code_failure_domain=false"
  "d3_runtime_native_probe_approval_external=true"
  "runtime_native_probe_execution=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "singleton_creation=false"
  "public_api_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
  "same_shape_no_accessor_wrapper=false"
)

for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_PROBE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing owner fact $fact" >&2
    exit 9
  fi
done

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$AGGREGATION_GUARD" > "$AGGREGATION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: recovery aggregation guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: log=$AGGREGATION_LOG" >&2
  exit 10
fi

required_aggregation_facts=(
  "route_classification=runtime_native_probe_recovery_guard_aggregation"
  "related_regression_guards_aggregated=true"
  "non_metal_recovery_route_landed=true"
  "automation_can_continue_non_d3_recovery=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_aggregation_facts[@]}"; do
  if ! grep -F "$fact" "$AGGREGATION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing aggregation fact $fact" >&2
    exit 11
  fi
done

if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: runtime package build failed" >&2
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: log=$BUILD_LOG" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: protected path modified" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: forbidden production native bridge diff found" >&2
  exit 14
fi

aggregation_packet="$(grep -Eo 'aggregation_packet_path=[^[:space:]]+' "$AGGREGATION_LOG" | tail -1 | cut -d= -f2-)"

if [[ -z "$aggregation_packet" || ! -f "$aggregation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing aggregation packet" >&2
  exit 15
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$aggregation_packet" | tail -1 | cut -d= -f2)"

{
  echo "source_build_probe_evidence_packet_version=1"
  echo "owner_probe_passed=true"
  echo "owner_probe_log=$OWNER_PROBE_LOG"
  echo "recovery_aggregation_guard_passed=true"
  echo "aggregation_log=$AGGREGATION_LOG"
  echo "aggregation_packet=$aggregation_packet"
  echo "runtime_package_build_passed=true"
  echo "runtime_package_build_log=$BUILD_LOG"
  echo "runtime_package_build_target=$BUILD_TARGET_DIR"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "source_build_probe_evidence_strengthened=true"
  echo "code_failure_domain=false"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$EVIDENCE_PACKET"

required_packet_facts=(
  "source_build_probe_evidence_packet_version=1"
  "owner_probe_passed=true"
  "recovery_aggregation_guard_passed=true"
  "runtime_package_build_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "code_failure_domain=false"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)

for fact in "${required_packet_facts[@]}"; do
  if ! grep -F "$fact" "$EVIDENCE_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: missing packet fact $fact" >&2
    exit 16
  fi
done

echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: route_classification=runtime_native_probe_source_build_probe_evidence_guard"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: recovery_aggregation_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: source_build_probe_evidence_strengthened=true"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: evidence_packet_path=$EVIDENCE_PACKET"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe source build probe evidence guard: next_route=focused_regression_suite_or_human_approved_d3_runtime_native_probe_execution"
