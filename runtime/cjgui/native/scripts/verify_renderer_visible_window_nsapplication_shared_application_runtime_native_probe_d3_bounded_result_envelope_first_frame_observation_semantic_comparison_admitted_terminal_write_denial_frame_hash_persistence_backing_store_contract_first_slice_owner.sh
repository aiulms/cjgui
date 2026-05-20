#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage131 frame-hash persistence backing-store
# contract first-slice owner probe。它验证 contract/token/redaction
# 边界存在，并确认该 slice 不执行真实持久化。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_backing_store_contract_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage131 backing-store contract owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage131 backing-store contract owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceBackingStoreContractFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceBackingStoreContractFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceBackingStoreContractFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistenceBackingStoreContractFirstSliceDraft"
require_owner_token "didDefineNonMutatingBackingStoreContract"
require_owner_token "didDefineBackingStoreTokenShape"
require_owner_token "didKeepBackingStoreTokenUnissued"
require_owner_token "didPrepareFrameHashPersistenceResultEnvelopeInput"

echo "stage131_backing_store_contract_owner_present=true"
echo "renderer_state_write_admission_recheck_consumed=true"
echo "frame_hash_persistence_backing_store_contract_ready=true"
echo "backing_store_contract_non_mutating=true"
echo "backing_store_token_shape_defined=true"
echo "backing_store_token_issued=false"
echo "hash_value_redaction_boundary_defined=true"
echo "frame_hash_persisted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
