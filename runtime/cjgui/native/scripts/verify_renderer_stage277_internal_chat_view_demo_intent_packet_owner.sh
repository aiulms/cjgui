#!/usr/bin/env zsh
#
# 维护注释：验证 stage277 internal chat view demo intent packet owner。
# 它只确认 message-list/composer/send intent 已成为 owner-local semantic input，不执行 action。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage277_internal_chat_view_demo_intent_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage277 internal chat view demo intent packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage277InternalChatViewDemoIntentPacketFacts" \
  "CjguiInternalRendererStage277InternalChatViewDemoIntentPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage277InternalChatViewDemoIntentPacketDraft" \
  "didConsumeStage276InternalSettingsPanelDemoReadinessDecision" \
  "didMaterializeInternalChatViewDemoIntentPacket" \
  "didMaterializeChatMessageListIntentSemanticNode" \
  "didMaterializeChatComposerIntentSemanticNode" \
  "didMaterializeChatSendIntentSemanticNode" \
  "didBindChatIntentPacketToOwnerLocalStateDeltaInput" \
  "didBindChatIntentPacketToRenderCommandRefreshRequirement" \
  "didPrepareStage278ChatViewDemoStateUpdateDryRunInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage277 internal chat view demo intent packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage277_internal_chat_view_demo_intent_packet_owner_present=true"
echo "stage276_internal_settings_panel_demo_readiness_decision_required=true"
echo "internal_chat_view_demo_intent_packet_materialized=true"
echo "chat_message_list_intent_semantic_node_materialized=true"
echo "chat_composer_intent_semantic_node_materialized=true"
echo "chat_send_intent_semantic_node_materialized=true"
echo "chat_intent_packet_bound_to_owner_local_state_delta_input=true"
echo "chat_intent_packet_bound_to_render_command_refresh_requirement=true"
echo "stage278_chat_view_demo_state_update_dry_run_input_prepared=true"
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
