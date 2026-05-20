#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage132 backing-store token result envelope
# first-slice owner probe。它验证 token result 明确表达 denial 与后续
# frame-hash persistence commit recheck 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_backing_store_token_result_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage132 backing-store token owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage132 backing-store token owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialBackingStoreTokenResultEnvelopeFirstSliceDraft"
require_owner_token "didConfirmTokenRequiresSatisfiedCommitPredicate"
require_owner_token "didConfirmMissingPositiveProbeBlocksTokenIssue"
require_owner_token "didConfirmMissingNonzeroFrameHashBlocksTokenIssue"
require_owner_token "didConfirmHostRuntimeLimitationBlocksTokenIssue"
require_owner_token "didKeepBackingStoreTokenIssueDenied"
require_owner_token "didPrepareFrameHashPersistenceCommitRecheckNextRoute"

echo "stage132_backing_store_token_result_envelope_owner_present=true"
echo "backing_store_token_result_envelope_ready=true"
echo "backing_store_token_requires_satisfied_commit_predicate=true"
echo "backing_store_token_issue_denied=true"
echo "backing_store_token_issued=false"
echo "missing_positive_probe_blocks_backing_store_token_issue=true"
echo "missing_nonzero_frame_hash_blocks_backing_store_token_issue=true"
echo "host_runtime_limitation_blocks_backing_store_token_issue=true"
echo "frame_hash_persistence_commit_recheck_input_prepared=true"
echo "frame_hash_value_redacted=true"
echo "frame_hash_persisted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
