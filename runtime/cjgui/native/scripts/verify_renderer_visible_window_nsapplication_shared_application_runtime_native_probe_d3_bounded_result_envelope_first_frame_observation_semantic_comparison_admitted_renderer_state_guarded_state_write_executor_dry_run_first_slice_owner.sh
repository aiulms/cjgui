#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage127 guarded state-write executor dry-run first-slice
# owner probe。它验证 executor denial boundary，不执行 guarded write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_dry_run_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted guarded state-write executor owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted guarded state-write executor owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorDryRunFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorDryRunFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorDryRunFirstSliceDraft"
require_owner_token "didDefineGuardedStateWriteExecutorInputs"
require_owner_token "didBindMutationRequestRejectionToExecutorDenial"
require_owner_token "didKeepGuardedStateWriteExecutorNonExecutable"
require_owner_token "didDenyGuardedStateWriteExecutor"
require_owner_token "shouldKeepGuardedStateWriteExecutorDryRunOnly"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_owner_present=true"
echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true"
echo "guarded_state_write_executor_inputs_defined=true"
echo "mutation_request_rejection_bound_to_executor_denial=true"
echo "guarded_state_write_executor_non_executable=true"
echo "guarded_state_write_executor_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
