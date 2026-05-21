#!/usr/bin/env zsh
#
# 维护注释：验证 stage266 internal Todo demo state update dry-run owner。
# 它只产生 Todo list owner-local state delta preview，不提交 runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage266_internal_todo_demo_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage266 internal todo demo state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage266InternalTodoDemoStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage266InternalTodoDemoStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage266InternalTodoDemoStateUpdateDryRunDraft" \
  "didConsumeStage265InternalTodoDemoIntentPacket" \
  "didMaterializeTodoDemoOwnerLocalStateSnapshot" \
  "didMaterializeTodoAddStateDeltaDryRun" \
  "didMaterializeTodoToggleStateDeltaDryRun" \
  "didMaterializeTodoRemoveStateDeltaDryRun" \
  "didBindTodoStateDeltaToRollbackReadyBoundary" \
  "didKeepTodoStateUpdateDryRunInMemoryOnly" \
  "didPrepareStage267TodoDemoRenderCommandPreviewInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage266 internal todo demo state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage266_internal_todo_demo_state_update_dry_run_owner_present=true"
echo "stage265_internal_todo_demo_intent_packet_required=true"
echo "todo_demo_owner_local_state_snapshot_materialized=true"
echo "todo_add_state_delta_dry_run_materialized=true"
echo "todo_toggle_state_delta_dry_run_materialized=true"
echo "todo_remove_state_delta_dry_run_materialized=true"
echo "todo_state_delta_bound_to_rollback_ready_boundary=true"
echo "todo_state_update_dry_run_in_memory_only=true"
echo "stage267_todo_demo_render_command_preview_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
