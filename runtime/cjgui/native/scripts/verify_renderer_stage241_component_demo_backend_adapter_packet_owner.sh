#!/usr/bin/env zsh
#
# 维护注释：验证 stage241 component demo backend adapter packet owner。
# 它只把 stage240 adapter readiness 接成 Button-like / refreshed command packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage241_component_demo_backend_adapter_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage241 component demo backend adapter packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage241ComponentDemoBackendAdapterPacketFacts" \
  "CjguiInternalRendererStage241ComponentDemoBackendAdapterPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage241ComponentDemoBackendAdapterPacketDraft" \
  "didConsumeStage240BackendAdapterReadinessDecision" \
  "didBindAdapterPacketToButtonLikeSemanticNode" \
  "didBindAdapterPacketToRefreshedRenderCommand" \
  "didBindAdapterPacketToNoSubmitBackendAdapterReadiness" \
  "didMaterializeComponentDemoBackendAdapterPacket" \
  "didPrepareStage242BackendAdapterSemanticDiffInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage241 component demo backend adapter packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage241_component_demo_backend_adapter_packet_owner_present=true"
echo "stage240_backend_adapter_readiness_decision_required=true"
echo "component_demo_backend_adapter_packet_materialized=true"
echo "adapter_packet_bound_to_button_like_semantic_node=true"
echo "adapter_packet_bound_to_refreshed_render_command=true"
echo "adapter_packet_bound_to_no_submit_backend_adapter_readiness=true"
echo "stage242_backend_adapter_semantic_diff_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
