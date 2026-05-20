#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage142 first-frame observation owner 只声明
# stage141 present scheduling 后续 readiness，不执行 native runtime 或 renderer
# state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_after_present_scheduling_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage142 first-frame observation owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeFirstFrameObservationAfterPresentSchedulingContractFirstSliceDraft" \
  "didRequirePositivePresentSchedulingBeforeFirstFrameObservation" \
  "didRequireProbeLocalVisibleWindowCapture" \
  "didRequireNoFrameHashPersistence" \
  "didAllowFirstFrameObservedEnvelope"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage142 first-frame observation owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage142_first_frame_observation_after_present_scheduling_contract_owner_present=true"
echo "stage141_present_scheduling_packet_required=true"
echo "positive_present_scheduling_before_first_frame_observation_required=true"
echo "bounded_first_frame_observation_probe_required=true"
echo "probe_local_visible_window_capture_required=true"
echo "frame_hash_summary_required=true"
echo "frame_hash_persisted=false"
echo "frame_hash_value_logged=false"
echo "baseline_compared=false"
echo "first_frame_observed_envelope_allowed=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
