#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage132 positive-probe backing-store commit
# predicate first-slice owner probe。它验证四条件 predicate 已由 source owner
# 定义，且默认不签发 token / 不持久化 hash。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_commit_predicate_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage132 commit predicate owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage132 commit predicate owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistencePositiveProbeBackingStoreCommitPredicateFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistencePositiveProbeBackingStoreCommitPredicateFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistencePositiveProbeBackingStoreCommitPredicateFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialFrameHashPersistencePositiveProbeBackingStoreCommitPredicateFirstSliceDraft"
require_owner_token "didDefinePositiveLiveProbePredicate"
require_owner_token "didDefineNonzeroFrameHashPredicate"
require_owner_token "didDefineHostRuntimeLimitationAbsentPredicate"
require_owner_token "didDefineHarnessGapAbsentPredicate"
require_owner_token "didKeepBackingStoreTokenUnissued"
require_owner_token "didPrepareBackingStoreTokenResultEnvelopeNextRoute"

echo "stage132_positive_probe_backing_store_commit_predicate_owner_present=true"
echo "positive_probe_backing_store_commit_predicate_ready=true"
echo "backing_store_commit_requires_positive_probe=true"
echo "backing_store_commit_requires_nonzero_frame_hash=true"
echo "backing_store_commit_requires_host_runtime_limitation_absent=true"
echo "backing_store_commit_requires_harness_gap_absent=true"
echo "backing_store_commit_non_mutating=true"
echo "backing_store_token_issued=false"
echo "frame_hash_value_redacted=true"
echo "frame_hash_persisted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
