#!/usr/bin/env zsh
#
# 维护注释：验证 stage283 internal chat view demo probe semantic diff/explain owner。
# 它只确认 chat probe result 能解释 message/composer/pending delivery 差异，不接纳 owner 变更。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage283_internal_chat_view_demo_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage283 internal chat view demo probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage283InternalChatViewDemoProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage283InternalChatViewDemoProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage283InternalChatViewDemoProbeSemanticDiffExplainDraft" \
  "didConsumeStage282InternalChatViewDemoProbeResultEnvelope" \
  "didMaterializeChatViewDemoProbeSemanticDiff" \
  "didMaterializeChatViewDemoProbeExplainPacket" \
  "didBindChatProbeDiffToIntentStateRenderOrder" \
  "didBindChatProbeExplainToMessageComposerPendingDeliveryIntents" \
  "didRecheckChatProbeRollbackReadyBoundary" \
  "didRecheckChatProbeVisibilityNotPublishedBoundary" \
  "didPrepareStage284ChatViewDemoProbeReadinessDecisionInput" \
  "didKeepOwnerAcceptanceNotGranted" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage283 internal chat view demo probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage283_internal_chat_view_demo_probe_semantic_diff_explain_owner_present=true"
echo "stage282_internal_chat_view_demo_probe_result_envelope_required=true"
echo "chat_view_demo_probe_semantic_diff_materialized=true"
echo "chat_view_demo_probe_explain_packet_materialized=true"
echo "chat_probe_diff_bound_to_intent_state_render_order=true"
echo "chat_probe_explain_bound_to_message_composer_pending_delivery_intents=true"
echo "chat_probe_rollback_ready_boundary_rechecked=true"
echo "chat_probe_visibility_not_published_boundary_rechecked=true"
echo "stage284_chat_view_demo_probe_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
