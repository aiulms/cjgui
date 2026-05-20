#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage128 visibility publication denial first-slice
# owner probe。它验证 guarded executor result envelope 已被消费，但
# visibility publication 仍停在 dry-run denial，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted visibility publication denial owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted visibility publication denial owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateVisibilityPublicationDenialFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateVisibilityPublicationDenialFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateVisibilityPublicationDenialFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateVisibilityPublicationDenialFirstSliceDraft"
require_owner_token "didConsumeGuardedStateWriteExecutorResultEnvelopeReadiness"
require_owner_token "didMaterializeVisibilityPublicationDenialEnvelope"
require_owner_token "didPersistGuardedExecutorDenialAsVisibilityDryRunFact"
require_owner_token "didPersistRollbackStopLineAsVisibilityDryRunFact"
require_owner_token "didDenyVisibilityPublication"
require_owner_token "shouldKeepVisibilityPublicationNonExecutable"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true"
echo "guarded_executor_result_envelope_consumed=true"
echo "visibility_publication_denial_envelope_materialized=true"
echo "guarded_executor_denial_persisted_as_visibility_dry_run_fact=true"
echo "rollback_stop_line_persisted_as_visibility_dry_run_fact=true"
echo "visibility_publication_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
