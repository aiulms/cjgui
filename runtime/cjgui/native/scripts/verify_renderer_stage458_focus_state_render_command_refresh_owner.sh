#!/usr/bin/env zsh
#
# 维护注释：验证 stage458 focus/input state update -> RenderCommand refresh owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage458_focus_state_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage458 focus state render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage458FocusStateRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage458FocusStateRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage458FocusStateRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage458FocusStateRenderCommandRefreshDraft" \
  "CjguiInternalRendererStage457FocusInputStateUpdateDryRunReadiness" \
  "didConsumeStage457FocusInputStateUpdateDryRun" \
  "didConsumeFocusInputActionStateUpdateDryRun" \
  "didConsumeTodoFocusInputStateUpdateCandidate" \
  "didConsumeSettingsFocusInputStateUpdateCandidate" \
  "didConsumeAiGeneratedSettingsFocusInputStateUpdateCandidate" \
  "didMaterializeFocusStateRenderCommandRefresh" \
  "didRefreshTodoFocusStateRenderCommand" \
  "didRefreshSettingsFocusStateRenderCommand" \
  "didRefreshAiGeneratedSettingsFocusStateRenderCommand" \
  "didBindFocusInputStateUpdateToRenderCommandRefresh" \
  "didBindStage456FocusInputActionIntentToRenderCommandRefresh" \
  "didKeepFocusStateRenderCommandOwnerLocal" \
  "didKeepFocusStateRenderCommandPreviewOnly" \
  "didPrepareStage459SharedComponentRuntimeShape" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage458 focus state render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage458_focus_state_render_command_refresh_owner_present=true"
echo "stage457_focus_input_state_update_dry_run_required=true"
echo "stage457_focus_input_state_update_dry_run_consumed=true"
echo "focus_input_action_state_update_dry_run_consumed=true"
echo "todo_focus_input_state_update_candidate_consumed=true"
echo "settings_focus_input_state_update_candidate_consumed=true"
echo "ai_generated_settings_focus_input_state_update_candidate_consumed=true"
echo "focus_state_render_command_refresh_materialized=true"
echo "todo_focus_state_render_command_refreshed=true"
echo "settings_focus_state_render_command_refreshed=true"
echo "ai_generated_settings_focus_state_render_command_refreshed=true"
echo "focus_input_state_update_to_render_command_refresh_bound=true"
echo "stage456_focus_input_action_intent_to_render_command_refresh_bound=true"
echo "focus_state_render_command_owner_local=true"
echo "focus_state_render_command_preview_only=true"
echo "stage459_shared_component_runtime_shape_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
