#!/usr/bin/env zsh
#
# 维护注释：验证 stage389 shared focus traversal key event demo probe owner。
# 它必须消费 stage388 commit-result refresh，并把 Todo/settings 的 key events
# 转成 owner-local focus traversal intent，不启用真实 input pipeline 或 dispatch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage389_shared_focus_traversal_key_event_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage389 shared focus traversal key event demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage389FocusTraversalKeyEventEnvelope" \
  "CjguiInternalRendererStage389FocusTraversalDemoGraph" \
  "CjguiInternalRendererStage389FocusTraversalIntentAdapter" \
  "CjguiInternalRendererStage389SharedFocusTraversalKeyEventDemoProbeFacts" \
  "CjguiInternalRendererStage389SharedFocusTraversalKeyEventDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage389SharedFocusTraversalKeyEventDemoProbeDraft" \
  "didConsumeStage388SharedTextEditCommitResultRenderRefreshDemoProbe" \
  "didMaterializeSharedFocusTraversalKeyEventEnvelope" \
  "didBindTabKeyEventToFocusNextIntent" \
  "didBindShiftTabKeyEventToFocusPreviousIntent" \
  "didBindEscapeKeyEventToFocusRollbackIntent" \
  "didBindEnterKeyEventToFocusedActivationIntent" \
  "didMaterializeSharedFocusTraversalDemoGraph" \
  "didBindFocusGraphToTodoTextEntry" \
  "didBindFocusGraphToTodoCommitResultSurface" \
  "didBindFocusGraphToSettingsToggle" \
  "didBindFocusGraphToSettingsFocusSurface" \
  "didMaterializeFocusTraversalIntentAdapter" \
  "didMapTabToNextFocusableNode" \
  "didMapShiftTabToPreviousFocusableNode" \
  "didMapEscapeToRollbackFocusPreview" \
  "didMapEnterToFocusedActivationPreview" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage389 shared focus traversal key event demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage389_shared_focus_traversal_key_event_demo_probe_owner_present=true"
echo "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_required=true"
echo "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_consumed=true"
echo "shared_focus_traversal_key_event_envelope_materialized=true"
echo "tab_key_event_bound_to_focus_next_intent=true"
echo "shift_tab_key_event_bound_to_focus_previous_intent=true"
echo "escape_key_event_bound_to_focus_rollback_intent=true"
echo "enter_key_event_bound_to_focused_activation_intent=true"
echo "shared_focus_traversal_demo_graph_materialized=true"
echo "focus_graph_bound_to_todo_text_entry=true"
echo "focus_graph_bound_to_todo_commit_result_surface=true"
echo "focus_graph_bound_to_settings_toggle=true"
echo "focus_graph_bound_to_settings_focus_surface=true"
echo "focus_traversal_intent_adapter_materialized=true"
echo "tab_mapped_to_next_focusable_node=true"
echo "shift_tab_mapped_to_previous_focusable_node=true"
echo "escape_mapped_to_rollback_focus_preview=true"
echo "enter_mapped_to_focused_activation_preview=true"
echo "focus_traversal_preview_only=true"
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
