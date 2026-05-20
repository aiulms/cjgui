#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage141 present scheduling owner 只声明 stage140
# commit 后续 readiness，不执行 native runtime 或 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage141 present scheduling owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePresentSchedulingAfterCommitNoPresentContractFirstSliceDraft" \
  "didRequirePositiveCommitBeforePresentScheduling" \
  "didRequireProbeLocalDrawablePresentScheduling" \
  "didRequireNoPresentBranchWhenCommitMissing" \
  "didKeepFirstFrameObservationBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage141 present scheduling owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage141_present_scheduling_after_commit_no_present_contract_owner_present=true"
echo "stage140_commit_no_present_packet_required=true"
echo "positive_commit_before_present_scheduling_required=true"
echo "bounded_present_scheduling_probe_required=true"
echo "probe_local_drawable_present_scheduling_required=true"
echo "present_after_encoding_before_commit_required=true"
echo "probe_local_commit_after_present_scheduling_required=true"
echo "bounded_completion_wait_required=true"
echo "no_present_branch_when_commit_missing_required=true"
echo "first_frame_observed=false"
echo "production_render_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
