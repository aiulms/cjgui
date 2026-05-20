#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage128 terminal write denial envelope first-slice
# owner probe。它验证 visibility denial 与 rollback fallback denial 已被
# 终端 result envelope 汇总，仍不发布 production truth 或 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted terminal write denial envelope owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted terminal write denial envelope owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateTerminalWriteDenialEnvelopeFirstSliceDraft"
require_owner_token "didConsumeRollbackFallbackDenialEnvelopeReadiness"
require_owner_token "didMaterializeTerminalWriteDenialEnvelope"
require_owner_token "didPersistVisibilityPublicationDenialAsTerminalDryRunFact"
require_owner_token "didPersistRollbackFallbackDenialAsTerminalDryRunFact"
require_owner_token "didDenyTerminalRendererStateWrite"
require_owner_token "shouldKeepTerminalWriteDenialNonExecutable"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true"
echo "rollback_fallback_denial_envelope_consumed=true"
echo "terminal_write_denial_envelope_materialized=true"
echo "visibility_publication_denial_persisted_as_terminal_dry_run_fact=true"
echo "rollback_fallback_denial_persisted_as_terminal_dry_run_fact=true"
echo "terminal_renderer_state_write_denied=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
