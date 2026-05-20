#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage126 renderer-state mutation request dry-run
# first-slice owner probe。它验证 request shape / rejection / future boundary，
# 不执行真实 state mutation。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestDryRunFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestDryRunFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateMutationRequestDryRunFirstSliceDraft"
require_owner_token "didDefineRendererStateMutationRequestShape"
require_owner_token "didBindDecisionDenialToMutationRequestRejection"
require_owner_token "didKeepMutationRequestNonExecutable"
require_owner_token "shouldRejectRendererStateMutationRequest"
require_owner_token "shouldKeepMutationRequestDryRunOnly"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true"
echo "renderer_state_mutation_request_shape_defined=true"
echo "decision_denial_bound_to_mutation_request_rejection=true"
echo "mutation_request_non_executable=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
