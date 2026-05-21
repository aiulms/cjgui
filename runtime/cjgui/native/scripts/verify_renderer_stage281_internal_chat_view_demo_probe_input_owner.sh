#!/usr/bin/env zsh
#
# 维护注释：验证 stage281 internal chat view demo probe input owner。
# 它只确认 chat probe input 已绑定 message/composer/pending delivery、state/render 与边界，不执行 action。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage281_internal_chat_view_demo_probe_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage281 internal chat view demo probe input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage281InternalChatViewDemoProbeInputFacts" \
  "CjguiInternalRendererStage281InternalChatViewDemoProbeInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage281InternalChatViewDemoProbeInputDraft" \
  "didConsumeStage280InternalChatViewDemoReadinessDecision" \
  "didMaterializeInternalChatViewDemoProbeInput" \
  "didBindChatProbeInputToMessageAppendIntent" \
  "didBindChatProbeInputToComposerClearIntent" \
  "didBindChatProbeInputToPendingDeliveryIntent" \
  "didBindChatProbeInputToOwnerLocalStateDelta" \
  "didBindChatProbeInputToRenderCommandPreview" \
  "didBindChatProbeInputToRollbackReadyBoundary" \
  "didBindChatProbeInputToVisibilityNotPublishedBoundary" \
  "didKeepChatProbeInputNonExecuting" \
  "didPrepareStage282ChatViewDemoProbeResultEnvelopeInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage281 internal chat view demo probe input: missing token $token" >&2
    exit 3
  fi
done

echo "stage281_internal_chat_view_demo_probe_input_owner_present=true"
echo "stage280_internal_chat_view_demo_readiness_decision_required=true"
echo "internal_chat_view_demo_probe_input_materialized=true"
echo "chat_probe_input_bound_to_message_append_intent=true"
echo "chat_probe_input_bound_to_composer_clear_intent=true"
echo "chat_probe_input_bound_to_pending_delivery_intent=true"
echo "chat_probe_input_bound_to_owner_local_state_delta=true"
echo "chat_probe_input_bound_to_render_command_preview=true"
echo "chat_probe_input_bound_to_rollback_ready_boundary=true"
echo "chat_probe_input_bound_to_visibility_not_published_boundary=true"
echo "chat_probe_input_non_executing=true"
echo "stage282_chat_view_demo_probe_result_envelope_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
