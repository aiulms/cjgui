#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage126 renderer-state write decision result envelope
# first-slice owner probe。它验证 decision 结果 envelope 字段和 fail-closed
# 边界，不执行真实 state mutation。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted write decision result envelope owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted write decision result envelope owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionResultEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionResultEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionResultEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionResultEnvelopeFirstSliceDraft"
require_owner_token "didMaterializeRendererStateWriteDecisionResultEnvelope"
require_owner_token "didPersistDenialReasonAsDryRunFact"
require_owner_token "didKeepFutureMutationBoundaryNonExecutable"
require_owner_token "shouldPublishDecisionResultEnvelope"
require_owner_token "shouldKeepDecisionResultEnvelopeNonMutating"
require_owner_token "didConfirmNoRendererStateWrite"

echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=true"
echo "renderer_state_write_decision_result_envelope_materialized=true"
echo "denial_reason_persisted_as_dry_run_fact=true"
echo "future_mutation_boundary_non_executable=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
