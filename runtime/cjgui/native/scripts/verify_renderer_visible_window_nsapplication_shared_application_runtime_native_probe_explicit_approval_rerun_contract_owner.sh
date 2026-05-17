#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 runtime native-readiness explicit approval rerun
# contract owner。它只做 source-level owner probe，不执行 runtime native probe，也不
# 消费 D3 approval。
# Truth: focused owner probe；验证 rerun contract owner 的符号、stage90 evidence
# mesh input、two-pass rerun、source/build guard、handoff packet 与 regression suite
# facts。
# Stop-line: 不调用 application singleton accessor，不创建或激活 NSApplication，
# 不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行
# cleanup / teardown，不创建 visible window，不 visible order，不取 drawable，
# 不 render / commit / present / GPU submission，不扩 public API / production C
# ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalHandoffEvidenceMeshReadiness"
  "didOpenExplicitApprovalRerunContractRoute"
  "didRequireTwoPassMeshRerunContract"
  "didRequireStableNonD3ApprovalFactsAcrossReruns"
  "didRequireSourceBuildGuard"
  "didRequireEvidenceHandoffPacket"
  "didRequireFocusedRegressionSuite"
  "didKeepMetalCapabilitySeparateFromD3Approval"
  "didKeepD3RuntimeNativeProbeApprovalExternal"
  "didKeepRuntimeNativeProbeExecutionBlocked"
  "didKeepHumanApprovedD3ExecutionUnconsumed"
  "didKeepCodeFailureDomainFalse"
  "didConfirmNoApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoSingletonCreation"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRendererStateWrite"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didAvoidSameShapeNoAccessorWrapper"
  "didKeepExplicitApprovalRerunContractDehydrated"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: explicit_approval_rerun_contract_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: explicit_approval_handoff_evidence_mesh_input=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: two_pass_mesh_rerun_contract_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: stable_non_d3_approval_facts_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: source_build_guard_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: evidence_handoff_packet_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: focused_regression_suite_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: metal_capability_separate_from_d3_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: d3_runtime_native_probe_approval_external=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: singleton_creation=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval rerun contract owner probe: same_shape_no_accessor_wrapper=false"
