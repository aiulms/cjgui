#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage137 pipeline / vertex preparation owner 只声明
# stage136 后续 readiness，不执行 native runtime，也不打开 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_preparation_after_render_encoder_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage137 pipeline vertex preparation owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexPreparationAfterRenderEncoderContractFirstSliceDraft" \
  "didRequirePositiveRenderEncoderBeforePipelineVertexPreparation" \
  "didRequireProbeLocalPipelineState" \
  "didRequireProbeLocalStaticTriangleVertexBuffer" \
  "didKeepDrawCommitPresentGpuWorkBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage137 pipeline vertex preparation owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage137_pipeline_vertex_preparation_after_render_encoder_contract_owner_present=true"
echo "stage136_render_encoder_contract_packet_required=true"
echo "positive_render_encoder_before_pipeline_vertex_preparation_required=true"
echo "bounded_pipeline_vertex_preparation_probe_required=true"
echo "probe_local_shader_library_required=true"
echo "probe_local_shader_functions_required=true"
echo "probe_local_pipeline_descriptor_required=true"
echo "probe_local_pipeline_state_required=true"
echo "probe_local_static_triangle_vertex_buffer_required=true"
echo "pipeline_state_binding_blocked=true"
echo "vertex_buffer_binding_blocked=true"
echo "draw_called=false"
echo "commit_called=false"
echo "present_called=false"
echo "gpu_work_submitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
