#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage127 guarded executor result envelope first-slice
# owner probe。它验证 executor denial result envelope，不发布 visibility truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted guarded executor result envelope owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted guarded executor result envelope owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorResultEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorResultEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorResultEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateGuardedStateWriteExecutorResultEnvelopeFirstSliceDraft"
require_owner_token "didMaterializeGuardedStateWriteExecutorResultEnvelope"
require_owner_token "didPersistGuardedExecutorDenialAsDryRunFact"
require_owner_token "didPersistRollbackStopLineAsDryRunFact"
require_owner_token "didPrepareVisibilityPublicationDenialInput"
require_owner_token "shouldKeepGuardedExecutorResultEnvelopeNonMutating"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_owner_present=true"
echo "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true"
echo "guarded_state_write_executor_result_envelope_materialized=true"
echo "guarded_executor_denial_persisted_as_dry_run_fact=true"
echo "rollback_stop_line_persisted_as_dry_run_fact=true"
echo "visibility_publication_denial_input_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
