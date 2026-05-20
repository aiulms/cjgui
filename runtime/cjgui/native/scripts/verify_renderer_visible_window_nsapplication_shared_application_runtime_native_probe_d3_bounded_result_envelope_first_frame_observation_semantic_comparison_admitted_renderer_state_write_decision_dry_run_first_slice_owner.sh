#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage126 renderer-state write decision dry-run
# first-slice owner probe。它只验证源码 owner / stop-line / decision 字段，
# 不执行 runtime native probe，不写 renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OWNER_FILE="$REPO_DIR/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice.cj"

require_owner_token() {
  local token="$1"
  if ! grep -F "$token" "$OWNER_FILE" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted write decision owner: missing token $token" >&2
    exit 2
  fi
}

if [[ ! -f "$OWNER_FILE" ]]; then
  echo "cjgui semantic-comparison-admitted write decision owner: missing owner file $OWNER_FILE" >&2
  exit 1
fi

require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionDryRunFirstSliceFacts"
require_owner_token "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionDryRunFirstSliceReadiness"
require_owner_token "cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionDryRunFirstSliceFacts"
require_owner_token "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationSemanticComparisonAdmittedRendererStateWriteDecisionDryRunFirstSliceDraft"
require_owner_token "didDefineRendererStateWriteDecisionInputFields"
require_owner_token "didDefineRendererStateWriteDenialReasons"
require_owner_token "didDefineFutureMutationBoundary"
require_owner_token "shouldAdmitRendererStateWriteDecisionDryRun"
require_owner_token "shouldDenyRendererStateWrite"
require_owner_token "didConfirmNoRuntimeStateWrite"

echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_owner_present=true"
echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=true"
echo "renderer_state_write_decision_input_fields_defined=true"
echo "renderer_state_write_denial_reasons_defined=true"
echo "future_mutation_boundary_defined=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
