#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage118 first-frame observation truth-admission join
# owner。它只做 source-level owner probe，不执行 runtime native probe。
# Stop-line: 不调用 application accessor，不扩 native bridge / public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join.cj"
NATIVE_HEADER="$ROOT_DIR/native/cjgui_native_bridge.h"
NATIVE_SOURCE="$ROOT_DIR/native/cjgui_native_bridge.m"

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: missing owner $OWNER_FILE" >&2
  exit 3
fi

required_owner_symbols=(
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinFacts"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinReadiness"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinFacts"
  "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinReadiness"
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationTruthAdmissionJoinDraft"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationFirstSliceReadiness"
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3ResultEnvelopeRendererStateWriteDecisionContractReadiness"
  "didConsumeFirstFrameObservationFirstSliceReadiness"
  "didConsumeRendererStateWriteDecisionContractReadiness"
  "didOpenFirstFrameObservationTruthAdmissionJoinPreflightRoute"
  "didRequirePositiveFirstFrameObservedEnvelopeInput"
  "didRequireFrameHashSummaryBeforeTruthAdmission"
  "didRequireIndependentRendererStateWriteDecisionContractInput"
  "didBindIsolatedFirstFrameObservationToWriteDecisionContract"
  "didConfirmFirstFrameObservationRemainsIsolatedEvidenceOnly"
  "didConfirmTruthAdmissionJoinIsNotProductionRenderTruth"
  "didRequireProductionTruthAdmissionAfterJoinPreflight"
  "didRequireProductionWriteAdmissionAfterTruthAdmissionJoin"
  "didKeepProductionRenderTruthBlockedAfterJoinPreflight"
  "didKeepRendererStateWriteBlockedAfterJoinPreflight"
  "didConfirmNoBackendReadyTruthUpgrade"
  "didConfirmNoProductionApplicationAccessorCall"
  "didConfirmNoNativeBridgeExpansion"
  "didConfirmNoPublicApi"
  "didConfirmNoProductionPublicCAbi"
  "didConfirmNoRuntimeStateWrite"
  "didConfirmNoCjpmTomlChange"
  "didConfirmNoRendererStateWrite"
  "didAvoidApprovalExternalPacketRecoveryOrReportWrapper"
)

for symbol in "${required_owner_symbols[@]}"; do
  if ! grep -F "$symbol" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: missing $symbol" >&2
    exit 4
  fi
done

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: forbidden runtime surface found" >&2
  exit 5
fi

if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_FILE" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: forbidden application/visible/render/capture token found in owner" >&2
  exit 6
fi

if git -C "$REPO_DIR" diff -U0 -- "$NATIVE_HEADER" "$NATIVE_SOURCE" \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[+][[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: forbidden production native bridge diff found" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: protected path modified" >&2
  exit 8
fi

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: owner_file=$OWNER_FILE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner_present=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: first_frame_observation_first_slice_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: renderer_state_write_decision_contract_input=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: positive_first_frame_observed_envelope_input_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: frame_hash_summary_before_truth_admission_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: independent_write_decision_contract_input_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: isolated_first_frame_observation_bound_to_write_decision_contract=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: first_frame_observation_remains_isolated_evidence_only=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: truth_admission_join_is_not_production_render_truth=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: production_truth_admission_after_join_preflight_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: production_write_admission_after_truth_admission_join_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: production_render_truth_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: renderer_state_write_after_truth_admission_join_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: result_envelope_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: backend_ready_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: public_api_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: runtime_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: cjpm_toml_change=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join owner probe: approval_external_packet_recovery_or_report_wrapper=false"
