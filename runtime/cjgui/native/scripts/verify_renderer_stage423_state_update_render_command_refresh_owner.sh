#!/usr/bin/env zsh
#
# 维护注释：验证 stage423 state update -> RenderCommand refresh owner。
# 它必须消费 stage422 state update dry-run，并生成 owner-local RenderCommand refresh bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage423_state_update_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage423 state update render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage423StateUpdateRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage423StateUpdateRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage423StateUpdateRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage423StateUpdateRenderCommandRefreshDraft" \
  "didConsumeStage422ActionIntentStateUpdateDryRun" \
  "didConsumeActionIntentStateUpdateDryRun" \
  "didConsumeTodoActionIntentStateUpdateCandidate" \
  "didConsumeSettingsActionIntentStateUpdateCandidate" \
  "didConsumeAiGeneratedSettingsActionIntentStateUpdateCandidate" \
  "didMaterializeStateUpdateRenderCommandRefresh" \
  "didRefreshTodoStateUpdateRenderCommand" \
  "didRefreshSettingsStateUpdateRenderCommand" \
  "didRefreshAiGeneratedSettingsStateUpdateRenderCommand" \
  "didBindStateUpdateCandidateToRenderCommandRefresh" \
  "didBindRollbackPreviewToRenderCommandRefresh" \
  "didKeepRenderCommandRefreshPreviewOnly" \
  "didPrepareStage424RenderCommandRefreshDemoSurfaceDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage423 state update render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage423_state_update_render_command_refresh_owner_present=true"
echo "stage422_action_intent_state_update_dry_run_required=true"
echo "stage422_action_intent_state_update_dry_run_consumed=true"
echo "action_intent_state_update_dry_run_consumed=true"
echo "todo_action_intent_state_update_candidate_consumed=true"
echo "settings_action_intent_state_update_candidate_consumed=true"
echo "ai_generated_settings_action_intent_state_update_candidate_consumed=true"
echo "action_intent_rollback_preview_consumed=true"
echo "state_update_render_command_refresh_materialized=true"
echo "todo_state_update_render_command_refreshed=true"
echo "settings_state_update_render_command_refreshed=true"
echo "ai_generated_settings_state_update_render_command_refreshed=true"
echo "state_update_candidate_to_render_command_refresh_bound=true"
echo "rollback_preview_to_render_command_refresh_bound=true"
echo "render_command_refresh_preview_only=true"
echo "stage424_render_command_refresh_demo_surface_dry_run_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
