#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage131 frame-hash persistence result envelope
# first-slice owner probe。它验证 backing-store contract 已接成 fail-closed
# persistence result，并继续禁止 hash value persistence。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_result_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage131 persistence result owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage131 persistence result owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceResultEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceResultEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceResultEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceResultEnvelopeFirstSliceDraft"
require_owner_token "didBindBackingStoreContractToPersistenceResult"
require_owner_token "didKeepPersistenceResultFailClosed"
require_owner_token "didKeepFrameHashPersistedFalse"
require_owner_token "didPrepareProductionTruthPromotionPersistenceRecheckInput"

echo "stage131_frame_hash_persistence_result_owner_present=true"
echo "frame_hash_persistence_backing_store_contract_consumed=true"
echo "frame_hash_persistence_result_envelope_ready=true"
echo "frame_hash_persistence_result_fail_closed=true"
echo "backing_store_token_issued=false"
echo "frame_hash_persisted=false"
echo "frame_hash_value_redacted=true"
echo "production_truth_promotion_persistence_recheck_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
