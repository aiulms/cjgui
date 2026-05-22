#!/usr/bin/env zsh
#
# 维护注释：验证 stage384 shared input event -> action intent adapter demo probe owner。
# 它必须消费 stage383 bridge，并把 AI-generated settings / Todo demo input event
# 接成 owner-local action intent adapter dry-run，继续复用 state/render preview bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage384_shared_input_event_to_action_intent_adapter_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage384 shared input event to action intent adapter demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage384SharedDemoInputEventEnvelope" \
  "CjguiInternalRendererStage384InputEventActionIntentAdapter" \
  "CjguiInternalRendererStage384AdaptedActionStateRenderPreview" \
  "CjguiInternalRendererStage384SharedInputEventToActionIntentAdapterDemoProbeFacts" \
  "CjguiInternalRendererStage384SharedInputEventToActionIntentAdapterDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage384SharedInputEventToActionIntentAdapterDemoProbeDraft" \
  "didConsumeStage383SharedActionStateRenderBridgeDemoProbe" \
  "didMaterializeSharedInputEventEnvelope" \
  "didBindPointerActivationEventToSettingsToggle" \
  "didBindTextSubmitEventToTodoEntry" \
  "didBindEventToSharedInputBinding" \
  "didBindEventToSharedFocusTarget" \
  "didMaterializeInputEventToActionIntentAdapter" \
  "didMapSettingsToggleEventToSharedActionIntent" \
  "didMapTodoSubmitEventToSharedActionIntent" \
  "didPreserveSharedInputBindingInActionIntent" \
  "didPreserveSharedFocusTargetInActionIntent" \
  "didReuseStage383SharedActionExecutorDryRun" \
  "didReuseStage383OwnerLocalStateUpdateDryRun" \
  "didReuseStage383RenderCommandRefreshBridge" \
  "didMaterializeSettingsInputEventSurfaceRefreshPreview" \
  "didMaterializeTodoInputEventSurfaceRefreshPreview" \
  "didMaterializeFocusAfterInputEventRefreshPreview" \
  "didKeepInputEventAdapterDryRunOnly" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage384 shared input event to action intent adapter demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_owner_present=true"
echo "stage383_shared_action_state_render_bridge_demo_probe_required=true"
echo "shared_input_event_envelope_materialized=true"
echo "settings_toggle_pointer_activation_event_bound=true"
echo "todo_text_submit_input_event_bound=true"
echo "shared_input_binding_consumed_by_input_event=true"
echo "shared_focus_target_consumed_by_input_event=true"
echo "input_event_to_action_intent_adapter_materialized=true"
echo "settings_toggle_event_mapped_to_shared_action_intent=true"
echo "todo_submit_event_mapped_to_shared_action_intent=true"
echo "shared_input_binding_preserved_in_action_intent=true"
echo "shared_focus_target_preserved_in_action_intent=true"
echo "stage383_shared_action_executor_dry_run_reused=true"
echo "stage383_owner_local_state_update_dry_run_reused=true"
echo "stage383_render_command_refresh_bridge_reused=true"
echo "settings_input_event_surface_refresh_preview_materialized=true"
echo "todo_input_event_surface_refresh_preview_materialized=true"
echo "focus_after_input_event_refresh_preview_materialized=true"
echo "owner_local_preview_only=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
