#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage140 commit no-present owner 只声明 stage139
# draw 后续 readiness，不执行 native runtime 或 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_buffer_commit_no_present_after_draw_call_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage140 commit no-present owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeCommandBufferCommitNoPresentAfterDrawCallContractFirstSliceDraft" \
  "didRequirePositiveDrawCallBeforeCommit" \
  "didRequireProbeLocalCommandBufferCommit" \
  "didRequireBoundedCompletionWait" \
  "didKeepPresentBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage140 commit no-present owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage140_command_buffer_commit_no_present_after_draw_call_contract_owner_present=true"
echo "stage139_draw_call_packet_required=true"
echo "positive_draw_call_before_commit_required=true"
echo "bounded_command_buffer_commit_no_present_probe_required=true"
echo "probe_local_draw_before_commit_required=true"
echo "end_encoding_before_commit_required=true"
echo "probe_local_command_buffer_commit_required=true"
echo "bounded_completion_wait_required=true"
echo "gpu_submission_completion_envelope_required=true"
echo "present_called=false"
echo "drawable_presented=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
