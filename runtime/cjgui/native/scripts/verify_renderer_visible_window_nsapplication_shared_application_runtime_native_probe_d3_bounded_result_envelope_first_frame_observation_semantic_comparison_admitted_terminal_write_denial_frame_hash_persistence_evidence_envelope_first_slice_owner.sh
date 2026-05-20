#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage130 frame-hash persistence evidence envelope
# first-slice owner probe。它只验证 redacted evidence schema 与 stop-line，
# 不读取或记录真实 frame hash value。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_evidence_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage130 frame-hash persistence evidence owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage130 frame-hash persistence evidence owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceEvidenceEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceEvidenceEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceEvidenceEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceEvidenceEnvelopeFirstSliceDraft"
require_owner_token "didDefineRedactedFrameHashPersistenceSchema"
require_owner_token "didRequirePositiveLiveProbeForFrameHashPersistence"
require_owner_token "didKeepFrameHashValueRedacted"
require_owner_token "didKeepFrameHashPersistedFalse"
require_owner_token "didPrepareProductionTruthPromotionPredicateMapInput"

echo "stage130_frame_hash_persistence_evidence_owner_present=true"
echo "write_readiness_closure_consumed=true"
echo "redacted_frame_hash_persistence_schema_defined=true"
echo "positive_live_probe_required_for_hash_persistence=true"
echo "frame_hash_value_redacted=true"
echo "frame_hash_persisted=false"
echo "production_truth_promotion_predicate_map_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
