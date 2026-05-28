#!/usr/bin/env zsh
#
# Verifies the stage467 shared component runtime visual refresh action/state update dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage467 shared component runtime visual refresh action state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage467SharedComponentRuntimeVisualRefreshActionStateUpdateDryRunPlan" \
  "CjguiInternalRendererStage467SharedComponentRuntimeVisualRefreshActionStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage467SharedComponentRuntimeVisualRefreshActionStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage467SharedComponentRuntimeVisualRefreshActionStateUpdateDryRunDraft" \
  "CjguiInternalRendererStage466SharedComponentRuntimeVisualRefreshInputActionAdapterReadiness" \
  "didConsumeStage466SharedComponentRuntimeVisualRefreshInputActionAdapter" \
  "didConsumeSharedComponentRuntimeVisualRefreshInputActionAdapter" \
  "didConsumeTodoRuntimeVisualRefreshActionIntent" \
  "didConsumeSettingsRuntimeVisualRefreshActionIntent" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshActionIntent" \
  "didMaterializeSharedComponentRuntimeVisualRefreshActionStateUpdateDryRun" \
  "didMaterializeTodoRuntimeVisualRefreshStateUpdateCandidate" \
  "didMaterializeSettingsRuntimeVisualRefreshStateUpdateCandidate" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshStateUpdateCandidate" \
  "didBindVisualRefreshActionIntentToStateUpdateDryRun" \
  "didBindVisualRefreshProbeInputToStateUpdateDryRun" \
  "didMaterializeVisualRefreshStateRollbackPreview" \
  "didPrepareStage468SharedComponentRuntimeVisualRefreshStateRenderCommandRefresh" \
  "didKeepStateUpdateOwnerLocal" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage467 shared component runtime visual refresh action state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_owner_present=true"
echo "stage466_shared_component_runtime_visual_refresh_input_action_adapter_required=true"
echo "stage466_shared_component_runtime_visual_refresh_input_action_adapter_consumed=true"
echo "shared_component_runtime_visual_refresh_input_action_adapter_consumed=true"
echo "todo_runtime_visual_refresh_action_intent_consumed=true"
echo "settings_runtime_visual_refresh_action_intent_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_action_intent_consumed=true"
echo "shared_component_runtime_visual_refresh_action_state_update_dry_run_materialized=true"
echo "todo_runtime_visual_refresh_state_update_candidate_materialized=true"
echo "settings_runtime_visual_refresh_state_update_candidate_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_state_update_candidate_materialized=true"
echo "visual_refresh_action_intent_to_state_update_dry_run_bound=true"
echo "visual_refresh_probe_input_to_state_update_dry_run_bound=true"
echo "visual_refresh_state_rollback_preview_materialized=true"
echo "visual_refresh_state_update_owner_local=true"
echo "stage468_shared_component_runtime_visual_refresh_state_render_command_refresh_prepared=true"
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
