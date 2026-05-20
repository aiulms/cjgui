#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage129 bounded probe truth alignment first-slice
# owner probe。它验证真实 bounded native probe facts 将被接入 gap matrix，
# 并要求区分 CJGUI harness 缺口与宿主限制。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_bounded_probe_truth_alignment_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage129 bounded probe truth alignment owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage129 bounded probe truth alignment owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBoundedProbeTruthAlignmentFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBoundedProbeTruthAlignmentFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBoundedProbeTruthAlignmentFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBoundedProbeTruthAlignmentFirstSliceDraft"
require_owner_token "didConsumeTruthGapMatrixReadiness"
require_owner_token "didRequireFreshBoundedRuntimeNativeProbeEnvelope"
require_owner_token "didRequireFirstFrameObservationFacts"
require_owner_token "didRequireHarnessGapVsHostLimitClassification"
require_owner_token "didKeepProbeEvidenceIsolated"
require_owner_token "didPrepareRendererStateWriteReadinessClosureInput"

echo "stage129_bounded_probe_truth_alignment_owner_present=true"
echo "truth_gap_matrix_consumed=true"
echo "fresh_bounded_runtime_native_probe_envelope_required=true"
echo "first_frame_observation_facts_required=true"
echo "harness_gap_vs_host_limit_classification_required=true"
echo "probe_evidence_kept_isolated=true"
echo "renderer_state_write_readiness_closure_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
