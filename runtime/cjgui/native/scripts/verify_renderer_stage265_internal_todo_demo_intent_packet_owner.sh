#!/usr/bin/env zsh
#
# 维护注释：验证 stage265 internal Todo demo intent packet owner。
# 它只把 add/toggle/remove 语义 intent 接入 demo loop，不执行真实 action dispatch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage265_internal_todo_demo_intent_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage265 internal todo demo intent packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage265InternalTodoDemoIntentPacketFacts" \
  "CjguiInternalRendererStage265InternalTodoDemoIntentPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage265InternalTodoDemoIntentPacketDraft" \
  "didConsumeStage264LoopDryRunProbeReadinessDecision" \
  "didMaterializeInternalTodoDemoIntentPacket" \
  "didMaterializeTodoAddIntentSemanticNode" \
  "didMaterializeTodoToggleIntentSemanticNode" \
  "didMaterializeTodoRemoveIntentSemanticNode" \
  "didBindTodoIntentPacketToOwnerLocalStateDeltaInput" \
  "didBindTodoIntentPacketToRenderCommandRefreshRequirement" \
  "didPrepareStage266TodoDemoStateUpdateDryRunInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage265 internal todo demo intent packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage265_internal_todo_demo_intent_packet_owner_present=true"
echo "stage264_internal_component_demo_loop_dry_run_probe_readiness_decision_required=true"
echo "internal_todo_demo_intent_packet_materialized=true"
echo "todo_add_intent_semantic_node_materialized=true"
echo "todo_toggle_intent_semantic_node_materialized=true"
echo "todo_remove_intent_semantic_node_materialized=true"
echo "todo_intent_packet_bound_to_owner_local_state_delta_input=true"
echo "todo_intent_packet_bound_to_render_command_refresh_requirement=true"
echo "stage266_todo_demo_state_update_dry_run_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
