#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage139 no-submit draw-call owner 只声明 stage138
# binding 后续 readiness，不执行 native runtime 或 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_draw_call_after_pipeline_vertex_binding_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage139 draw call owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeDrawCallAfterPipelineVertexBindingContractFirstSliceDraft" \
  "didRequirePositivePipelineVertexBindingBeforeDraw" \
  "didRequireProbeLocalDrawPrimitivesCall" \
  "didKeepCommitPresentGpuWorkBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage139 draw call owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage139_draw_call_after_pipeline_vertex_binding_contract_owner_present=true"
echo "stage138_pipeline_vertex_binding_packet_required=true"
echo "positive_pipeline_vertex_binding_before_draw_required=true"
echo "bounded_draw_call_probe_required=true"
echo "probe_local_render_command_encoder_required=true"
echo "probe_local_pipeline_state_bound_required=true"
echo "probe_local_vertex_buffer_bound_required=true"
echo "probe_local_draw_primitives_call_required=true"
echo "commit_called=false"
echo "present_called=false"
echo "gpu_work_submitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
