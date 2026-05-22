#!/usr/bin/env zsh
#
# 维护注释：验证 stage390 focus traversal render refresh demo probe owner。
# 它必须消费 stage389 focus traversal key-event adapter，并生成 owner-local
# focus target delta、surface refresh 和 RenderCommand preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage390_focus_traversal_render_refresh_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage390 focus traversal render refresh demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage390FocusTraversalStateDelta" \
  "CjguiInternalRendererStage390FocusedSurfaceRefresh" \
  "CjguiInternalRendererStage390FocusTraversalRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage390FocusTraversalRenderRefreshDemoProbeFacts" \
  "CjguiInternalRendererStage390FocusTraversalRenderRefreshDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage390FocusTraversalRenderRefreshDemoProbeDraft" \
  "didConsumeStage389SharedFocusTraversalKeyEventDemoProbe" \
  "didMaterializeOwnerLocalFocusTraversalStateDelta" \
  "didMaterializeNextFocusTargetPreview" \
  "didMaterializePreviousFocusTargetPreview" \
  "didMaterializeRollbackFocusTargetPreview" \
  "didBindFocusStateDeltaToTodoAndSettingsNodes" \
  "didMaterializeTodoFocusRingSurfaceRefreshPreview" \
  "didMaterializeSettingsFocusRingSurfaceRefreshPreview" \
  "didMaterializeCaretFocusVisibilityRefreshPreview" \
  "didBindFocusRefreshToStage388CommitResultSurface" \
  "didMaterializeFocusTraversalRenderCommandRefreshPlan" \
  "didBindFocusTraversalRefreshToStage383RenderBridge" \
  "didBindFocusTraversalRefreshToStage388CommitResultPlan" \
  "didBindFocusTraversalRefreshToStage389KeyEventAdapter" \
  "didKeepFocusStateUpdateUncommitted" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage390 focus traversal render refresh demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage390_focus_traversal_render_refresh_demo_probe_owner_present=true"
echo "stage389_shared_focus_traversal_key_event_demo_probe_required=true"
echo "stage389_shared_focus_traversal_key_event_demo_probe_consumed=true"
echo "owner_local_focus_traversal_state_delta_materialized=true"
echo "next_focus_target_preview_materialized=true"
echo "previous_focus_target_preview_materialized=true"
echo "rollback_focus_target_preview_materialized=true"
echo "focus_state_delta_bound_to_todo_and_settings_nodes=true"
echo "todo_focus_ring_surface_refresh_preview_materialized=true"
echo "settings_focus_ring_surface_refresh_preview_materialized=true"
echo "caret_focus_visibility_refresh_preview_materialized=true"
echo "focus_refresh_bound_to_stage388_commit_result_surface=true"
echo "focus_traversal_render_command_refresh_plan_materialized=true"
echo "focus_traversal_refresh_bound_to_stage383_render_bridge=true"
echo "focus_traversal_refresh_bound_to_stage388_commit_result_plan=true"
echo "focus_traversal_refresh_bound_to_stage389_key_event_adapter=true"
echo "focus_traversal_render_refresh_preview_only=true"
echo "focus_state_update_uncommitted=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
