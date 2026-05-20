#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage133 renderer-state write token gate recheck
# first-slice owner probe。它要求 renderer-state write 必须等待 production
# truth gate admitted、backend-ready truth admitted，并继续禁止 runtime_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_token_gate_recheck_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui stage133 renderer state write token gate recheck owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui stage133 renderer state write token gate recheck owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedTerminalWriteDenialRendererStateWriteTokenGateRecheckFirstSliceDraft"
require_owner_token "didConsumeProductionTruthTokenGateRecheck"
require_owner_token "didRequireProductionTruthBeforeRendererStateWrite"
require_owner_token "didRequireBackendReadyTruthBeforeRendererStateWrite"
require_owner_token "didKeepRendererStateWriteAdmissionBlocked"
require_owner_token "didPreparePositiveHostRerunNextRoute"

echo "stage133_renderer_state_write_token_gate_recheck_owner_present=true"
echo "renderer_state_write_token_gate_recheck_ready=true"
echo "renderer_state_write_requires_production_truth=true"
echo "renderer_state_write_requires_backend_ready_truth=true"
echo "renderer_state_write_admission_ready=false"
echo "positive_host_rerun_next_route_prepared=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
