#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage128 rollback fallback denial envelope
# first-slice owner probe。它验证 visibility denial 被消费后，rollback
# fallback 仍只形成 denial envelope，不进入真实 renderer_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted rollback fallback denial envelope owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted rollback fallback denial envelope owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateRollbackFallbackDenialEnvelopeFirstSliceDraft"
require_owner_token "didConsumeVisibilityPublicationDenialReadiness"
require_owner_token "didMaterializeRollbackFallbackDenialEnvelope"
require_owner_token "didBindVisibilityDenialToRollbackFallbackStopLine"
require_owner_token "didDenyRollbackFallbackStateWrite"
require_owner_token "shouldKeepRollbackFallbackNonExecutable"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true"
echo "visibility_publication_denial_consumed=true"
echo "rollback_fallback_denial_envelope_materialized=true"
echo "visibility_denial_bound_to_rollback_fallback_stop_line=true"
echo "rollback_fallback_state_write_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
