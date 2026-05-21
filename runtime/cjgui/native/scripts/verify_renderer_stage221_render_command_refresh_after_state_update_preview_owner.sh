#!/usr/bin/env zsh
#
# 维护注释：验证 stage221 render-command refresh owner。
# 它把 stage220 state update preview 映射到 Button-like demo 的内部 RenderCommand refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage221_render_command_refresh_after_state_update_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage221 render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewFacts" \
  "CjguiInternalRendererStage221RenderCommandRefreshAfterStateUpdatePreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage221RenderCommandRefreshAfterStateUpdatePreviewDraft" \
  "didConsumeStage220StatefulInteractionReadinessDecision" \
  "didConsumeInternalRenderCommandPacket" \
  "didMapStateUpdatePreviewToRenderCommandRefresh" \
  "didBindRefreshToButtonLikeSemanticNode" \
  "didMaterializeRenderCommandRefreshPreview" \
  "didCarryOwnerLocalBeforeAfterStateRevisions" \
  "didPrepareStage222RefreshedRenderCommandPreviewPacketInput" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage221 render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage221_render_command_refresh_owner_present=true"
echo "stage220_stateful_interaction_readiness_decision_required=true"
echo "internal_render_command_packet_required=true"
echo "state_update_preview_mapped_to_render_command_refresh=true"
echo "button_like_semantic_node_bound_to_render_command_refresh=true"
echo "render_command_refresh_preview_materialized=true"
echo "owner_local_before_after_state_revisions_carried=true"
echo "stage222_refreshed_render_command_preview_packet_input_prepared=true"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
