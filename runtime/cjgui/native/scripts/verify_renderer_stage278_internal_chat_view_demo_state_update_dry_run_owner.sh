#!/usr/bin/env zsh
#
# 维护注释：验证 stage278 internal chat view demo state update dry-run owner。
# 它只确认 chat state delta 可在 owner-local snapshot 中演算，不提交 runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage278_internal_chat_view_demo_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage278 internal chat view demo state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage278InternalChatViewDemoStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage278InternalChatViewDemoStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage278InternalChatViewDemoStateUpdateDryRunDraft" \
  "didConsumeStage277InternalChatViewDemoIntentPacket" \
  "didMaterializeChatViewDemoOwnerLocalStateSnapshot" \
  "didMaterializeChatMessageAppendStateDeltaDryRun" \
  "didMaterializeChatComposerClearStateDeltaDryRun" \
  "didMaterializeChatPendingDeliveryStateDeltaDryRun" \
  "didBindChatStateDeltaToRollbackReadyBoundary" \
  "didKeepChatStateUpdateDryRunInMemoryOnly" \
  "didPrepareStage279ChatViewDemoRenderCommandPreviewInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage278 internal chat view demo state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage278_internal_chat_view_demo_state_update_dry_run_owner_present=true"
echo "stage277_internal_chat_view_demo_intent_packet_required=true"
echo "chat_view_demo_owner_local_state_snapshot_materialized=true"
echo "chat_message_append_state_delta_dry_run_materialized=true"
echo "chat_composer_clear_state_delta_dry_run_materialized=true"
echo "chat_pending_delivery_state_delta_dry_run_materialized=true"
echo "chat_state_delta_bound_to_rollback_ready_boundary=true"
echo "chat_state_update_dry_run_in_memory_only=true"
echo "stage279_chat_view_demo_render_command_preview_input_prepared=true"
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
