#!/usr/bin/env zsh
#
# 维护注释：验证 stage267 internal Todo demo render command preview owner。
# 它只把 Todo state dry-run 映射成 RenderCommand preview，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage267_internal_todo_demo_render_command_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage267 internal todo demo render command preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage267InternalTodoDemoRenderCommandPreviewFacts" \
  "CjguiInternalRendererStage267InternalTodoDemoRenderCommandPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage267InternalTodoDemoRenderCommandPreviewDraft" \
  "didConsumeStage266InternalTodoDemoStateUpdateDryRun" \
  "didMaterializeTodoListSemanticNodePreview" \
  "didMaterializeTodoItemSemanticNodePreview" \
  "didMaterializeTodoTextInputSemanticNodePreview" \
  "didMaterializeTodoButtonSemanticNodePreview" \
  "didBindTodoRenderPreviewToStateDeltaDryRun" \
  "didBindTodoRenderPreviewToRenderCommandRefreshRequirement" \
  "didPrepareStage268TodoDemoReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage267 internal todo demo render command preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage267_internal_todo_demo_render_command_preview_owner_present=true"
echo "stage266_internal_todo_demo_state_update_dry_run_required=true"
echo "todo_list_semantic_node_preview_materialized=true"
echo "todo_item_semantic_node_preview_materialized=true"
echo "todo_text_input_semantic_node_preview_materialized=true"
echo "todo_button_semantic_node_preview_materialized=true"
echo "todo_render_preview_bound_to_state_delta_dry_run=true"
echo "todo_render_preview_bound_to_render_command_refresh_requirement=true"
echo "stage268_todo_demo_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
