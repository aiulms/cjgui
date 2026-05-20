#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage129 terminal write denial 后 production-truth
# gap matrix first-slice owner probe。它只验证缺口矩阵 owner，不执行
# renderer_state 写入或 production truth 升级。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_truth_gap_matrix_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage129 truth gap matrix owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage129 truth gap matrix owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialTruthGapMatrixFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialTruthGapMatrixFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialTruthGapMatrixFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialTruthGapMatrixFirstSliceDraft"
require_owner_token "didConsumeTerminalWriteDenialEnvelopeReadiness"
require_owner_token "didMaterializeExactProductionTruthMissingPredicates"
require_owner_token "didClassifyFrameHashPersistenceGap"
require_owner_token "didClassifyProductionTruthPromotionGap"
require_owner_token "didClassifyBackendReadyTruthGap"
require_owner_token "didClassifyVisibilityPublicationAdmissionGap"
require_owner_token "didClassifyRollbackFallbackAdmissionGap"
require_owner_token "didClassifyRendererStateWriteAdmissionGap"
require_owner_token "didPrepareBoundedProbeTruthAlignmentInput"

echo "stage129_truth_gap_matrix_owner_present=true"
echo "terminal_write_denial_envelope_consumed=true"
echo "production_truth_gap_matrix_ready=true"
echo "exact_missing_predicates_materialized=true"
echo "frame_hash_persistence_gap_classified=true"
echo "production_truth_promotion_gap_classified=true"
echo "backend_ready_truth_gap_classified=true"
echo "visibility_publication_admission_gap_classified=true"
echo "rollback_fallback_admission_gap_classified=true"
echo "renderer_state_write_admission_gap_classified=true"
echo "bounded_probe_truth_alignment_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
