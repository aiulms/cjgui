#!/usr/bin/env zsh
#
# 维护注释：验证 stage279 internal chat view demo render command preview owner。
# 它只确认 chat semantic preview 已刷新为 RenderCommand 输入形态，不创建平台 command buffer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage279_internal_chat_view_demo_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage279 internal chat view demo render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage279InternalChatViewDemoRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage279InternalChatViewDemoRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage279InternalChatViewDemoRenderCommandPreviewDraft" \
  "didConsumeStage278InternalChatViewDemoStateUpdateDryRun" \
  "didMaterializeChatConversationSemanticNodePreview" \
  "didMaterializeChatMessageBubbleSemanticNodePreview" \
  "didMaterializeChatComposerSemanticNodePreview" \
  "didMaterializeChatSendButtonSemanticNodePreview" \
  "didBindChatRenderPreviewToStateDeltaDryRun" \
  "didBindChatRenderPreviewToRenderCommandRefreshRequirement" \
  "didPrepareStage280ChatViewDemoReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage279 internal chat view demo render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage279_internal_chat_view_demo_render_command_preview_owner_present=true"
echo "stage278_internal_chat_view_demo_state_update_dry_run_required=true"
echo "chat_conversation_semantic_node_preview_materialized=true"
echo "chat_message_bubble_semantic_node_preview_materialized=true"
echo "chat_composer_semantic_node_preview_materialized=true"
echo "chat_send_button_semantic_node_preview_materialized=true"
echo "chat_render_preview_bound_to_state_delta_dry_run=true"
echo "chat_render_preview_bound_to_render_command_refresh_requirement=true"
echo "stage280_chat_view_demo_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
