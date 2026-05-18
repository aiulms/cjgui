#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 D3 bounded result-envelope admission owner。
# 它只做 source-level owner probe，不执行 runtime native probe。
# Stop-line: 不调用 application accessor，不扩 native bridge / public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeAdmissionDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedRuntimeExecutionReadiness"
  "didConsumeBoundedRuntimeExecutionReadiness"
  "didOpenBoundedResultEnvelopeAdmissionRoute"
  "didRequireBoundedRuntimeExecutionResultEnvelope"
  "didRequireExecutedAndPassedBoundedResultEnvelope"
  "didAdmitSuccessfulBoundedResultEnvelope"
  "didRejectSkippedOrFailedBoundedResultEnvelope"
  "didKeepResultEnvelopeAsIsolatedEvidenceOnly"
  "didConfirmResultEnvelopeIsNotProductionTruth"
  "didRequireNoPointerOrNativeObjectPayload"
  "didRequireNoBackendReadyTruthUpgrade"
  "didKeepRendererStateWriteBlocked"
  "didRequireSourceBuildGuardBeforeNextRoute"
  "didConfirmNoProductionApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoRendererStateWrite"
  "didAvoidApprovalOrExternalPacketWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: forbidden application/visible/render token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: d3_bounded_result_envelope_admission_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: bounded_runtime_execution_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: bounded_runtime_execution_result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: executed_and_passed_result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: successful_bounded_result_envelope_admission_route=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: skipped_or_failed_result_envelope_rejected=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: isolated_result_envelope_evidence_only=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: result_envelope_is_not_production_truth=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: no_pointer_or_native_object_payload=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: backend_ready_truth_upgrade=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: source_build_guard_before_next_route_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission owner probe: approval_or_external_packet_wrapper=false"
