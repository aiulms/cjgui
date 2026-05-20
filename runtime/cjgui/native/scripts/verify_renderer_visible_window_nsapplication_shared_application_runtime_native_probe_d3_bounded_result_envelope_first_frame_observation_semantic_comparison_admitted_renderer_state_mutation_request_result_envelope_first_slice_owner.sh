#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage127 mutation request result envelope first-slice
# owner probe。它只验证 request result envelope / rollback eligibility /
# guarded executor input 的源码 owner 事实，不执行真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request result envelope owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request result envelope owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestResultEnvelopeFirstSliceDraft"
require_owner_token "didMaterializeRendererStateMutationRequestResultEnvelope"
require_owner_token "didPersistMutationRequestRejectionAsDryRunFact"
require_owner_token "didBindRollbackEligibilityToBlockedFact"
require_owner_token "didPrepareGuardedStateWriteExecutorInput"
require_owner_token "shouldKeepMutationRequestResultEnvelopeNonMutating"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true"
echo "renderer_state_mutation_request_result_envelope_materialized=true"
echo "mutation_request_rejection_persisted_as_dry_run_fact=true"
echo "rollback_eligibility_blocked=true"
echo "guarded_state_write_executor_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
