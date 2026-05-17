#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness non-D3 rerun maintenance
# owner。它只做 source-level owner probe，不执行 runtime native probe，也不消费
# D3 approval。
# Truth: focused owner probe；验证 non-D3 rerun maintenance owner 的符号、
# source/build/probe input、packet integrity / failure-domain replay /
# orchestration / aggregate guard facts 与 stop-line。
# Stop-line: 不调用 application singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 visible window，不 visible order，不 nextDrawable，
# 不 render / commit / present / GPU submission，不扩 public API / production C ABI，
# 不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_rerun_maintenance.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeNonD3RerunMaintenanceDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeSourceBuildProbeEvidenceReadiness"
  "didOpenNonD3RerunMaintenanceRoute"
  "didRequireFreshFocusedRegressionSuiteRerun"
  "didRequireAnchoredPacketIntegrityGuard"
  "didRequireFailureDomainReplay"
  "didRequireOrchestrationRunner"
  "didRequireMaintenanceAggregateGuard"
  "didKeepAutomationEnvironmentBlockerClassified"
  "didKeepCodeFailureDomainFalse"
  "didKeepD3RuntimeNativeProbeApprovalExternal"
  "didKeepRuntimeNativeProbeExecutionBlocked"
  "didConfirmNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoSingletonCreation"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didAvoidSameShapeNoAccessorWrapper"
  "didKeepNonD3RerunMaintenanceDehydrated"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: non_d3_rerun_maintenance_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: source_build_probe_evidence_input=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: non_d3_rerun_maintenance_route=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: fresh_focused_regression_suite_rerun_required=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: anchored_packet_integrity_guard_required=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: failure_domain_replay_required=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: orchestration_runner_required=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: maintenance_aggregate_guard_required=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: automation_environment_blocker_classified=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: d3_runtime_native_probe_approval_external=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: singleton_creation=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 rerun maintenance owner probe: same_shape_no_accessor_wrapper=false"
