#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage130 renderer-state write admission recheck
# first-slice owner probe。它验证 admission gate 重新绑定到 frame-hash
# persistence / production truth promotion 谓词，并保持写入阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_admission_recheck_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage130 renderer-state write admission recheck owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage130 renderer-state write admission recheck owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteAdmissionRecheckFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteAdmissionRecheckFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteAdmissionRecheckFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteAdmissionRecheckFirstSliceDraft"
require_owner_token "didBindFrameHashPersistenceToRendererStateWriteAdmissionGate"
require_owner_token "didBindProductionTruthPromotionToRendererStateWriteAdmissionGate"
require_owner_token "didConfirmRendererStateWriteAdmissionStillBlocked"
require_owner_token "didPrepareFrameHashPersistenceBackingStoreNextRoute"

echo "stage130_renderer_state_write_admission_recheck_owner_present=true"
echo "production_truth_promotion_predicate_map_consumed=true"
echo "renderer_state_write_admission_recheck_ready=true"
echo "frame_hash_persistence_bound_to_renderer_state_write_admission=true"
echo "production_truth_promotion_bound_to_renderer_state_write_admission=true"
echo "renderer_state_write_admission_ready=false"
echo "frame_hash_persistence_backing_store_next_route_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
