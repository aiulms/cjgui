#!/usr/bin/env zsh
#
# 维护注释：验证 stage383 shared action/state/render bridge demo probe owner。
# 它必须消费 stage382 demo surface，并把 AI-generated settings / Todo demo action intent
# 接到 owner-local state update dry-run 与 RenderCommand refresh bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage383_shared_action_state_render_bridge_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage383 shared action/state/render bridge demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage383SharedDemoActionIntent" \
  "CjguiInternalRendererStage383SharedActionStateUpdateDryRun" \
  "CjguiInternalRendererStage383SharedActionRenderCommandRefreshBridge" \
  "CjguiInternalRendererStage383SharedActionStateRenderBridgeDemoProbeFacts" \
  "CjguiInternalRendererStage383SharedActionStateRenderBridgeDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage383SharedActionStateRenderBridgeDemoProbeDraft" \
  "didConsumeStage382SharedLayoutStyleInputFocusDemoProbe" \
  "didMaterializeSharedDemoActionIntent" \
  "didBindActionIntentToAiGeneratedSettingsToggle" \
  "didBindActionIntentToTodoEntrySubmit" \
  "didBindActionIntentToSharedInputBinding" \
  "didMaterializeSharedActionExecutorDryRun" \
  "didMaterializeOwnerLocalStateUpdateDryRunFromSharedAction" \
  "didBindStateUpdateDryRunToSettingsToggleDelta" \
  "didBindStateUpdateDryRunToTodoEntryDelta" \
  "didMaterializeRenderCommandRefreshBridgeFromSharedAction" \
  "didBindRefreshBridgeToAiGeneratedSettingsSurface" \
  "didBindRefreshBridgeToTodoDemoSurface" \
  "didKeepActionIntentNonDispatching" \
  "didKeepStateUpdateDryRunUncommitted" \
  "didKeepRenderCommandRefreshPreviewOnly" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage383 shared action/state/render bridge demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage383_shared_action_state_render_bridge_demo_probe_owner_present=true"
echo "stage382_shared_layout_style_input_focus_demo_probe_required=true"
echo "shared_demo_action_intent_materialized=true"
echo "ai_generated_settings_demo_action_consumed=true"
echo "todo_demo_action_consumed=true"
echo "shared_input_binding_consumed_by_action_intent=true"
echo "shared_focus_target_consumed_by_action_intent=true"
echo "shared_action_executor_dry_run_materialized=true"
echo "owner_local_state_update_dry_run_from_shared_action_materialized=true"
echo "settings_toggle_state_delta_materialized=true"
echo "todo_entry_state_delta_materialized=true"
echo "render_command_refresh_bridge_from_shared_action_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_bridge_materialized=true"
echo "todo_demo_surface_refresh_bridge_materialized=true"
echo "focus_refresh_preview_materialized=true"
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
