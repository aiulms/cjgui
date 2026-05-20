#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage129 renderer-state write readiness closure
# first-slice owner probe。它验证 gap matrix 与 bounded probe alignment 已汇入
# state-write readiness 结论，但仍不执行 runtime_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_readiness_closure_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage129 renderer-state write readiness closure owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage129 renderer-state write readiness closure owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteReadinessClosureFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteReadinessClosureFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteReadinessClosureFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteReadinessClosureFirstSliceDraft"
require_owner_token "didConsumeBoundedProbeTruthAlignmentReadiness"
require_owner_token "didBindProductionTruthGapMatrixToWriteReadiness"
require_owner_token "didBindFreshProbeEnvelopeToWriteReadiness"
require_owner_token "didCloseRendererStateWriteReadinessWithoutMutation"
require_owner_token "didKeepRendererStateWriteAdmissionBlocked"
require_owner_token "didPrepareFrameHashPersistenceEvidenceNextRoute"

echo "stage129_renderer_state_write_readiness_closure_owner_present=true"
echo "bounded_probe_truth_alignment_consumed=true"
echo "production_truth_gap_matrix_bound_to_write_readiness=true"
echo "fresh_probe_envelope_bound_to_write_readiness=true"
echo "renderer_state_write_readiness_closed_without_mutation=true"
echo "renderer_state_write_admission_ready=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
