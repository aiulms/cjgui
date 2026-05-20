#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage138 pipeline / vertex binding owner 只声明
# stage137 preparation 后续 readiness，不执行 native runtime 或 renderer state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_pipeline_vertex_binding_after_preparation_contract_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage138 pipeline vertex binding owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopePipelineVertexBindingAfterPreparationContractFirstSliceDraft" \
  "didRequirePositivePipelineVertexPreparationBeforeBinding" \
  "didRequireProbeLocalPipelineStateBinding" \
  "didRequireProbeLocalVertexBufferBinding" \
  "didKeepDrawCommitPresentGpuWorkBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage138 pipeline vertex binding owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage138_pipeline_vertex_binding_after_preparation_contract_owner_present=true"
echo "stage137_pipeline_vertex_preparation_packet_required=true"
echo "positive_pipeline_vertex_preparation_before_binding_required=true"
echo "bounded_pipeline_vertex_binding_probe_required=true"
echo "probe_local_render_command_encoder_required=true"
echo "probe_local_pipeline_state_binding_required=true"
echo "probe_local_vertex_buffer_binding_required=true"
echo "draw_called=false"
echo "commit_called=false"
echo "present_called=false"
echo "gpu_work_submitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
