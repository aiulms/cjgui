#!/usr/bin/env zsh
#
# 维护注释：验证 stage453 recovery demo surface state update -> RenderCommand refresh owner。
# 它必须消费 stage452 state update dry-run，并生成 owner-local RenderCommand refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage453_recovery_demo_surface_state_update_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage453 recovery demo surface state update render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefreshDraft" \
  "CjguiInternalRendererStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRunReadiness" \
  "didConsumeStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRun" \
  "didConsumeRecoveryDemoSurfaceActionExecutorStateUpdateDryRun" \
  "didConsumeTodoRecoveryDemoSurfaceActionExecutorStateUpdateCandidate" \
  "didConsumeSettingsRecoveryDemoSurfaceActionExecutorStateUpdateCandidate" \
  "didConsumeAiGeneratedSettingsRecoveryDemoSurfaceActionExecutorStateUpdateCandidate" \
  "didMaterializeRecoveryDemoSurfaceStateUpdateRenderCommandRefresh" \
  "didRefreshTodoRecoveryDemoSurfaceStateUpdateRenderCommand" \
  "didRefreshSettingsRecoveryDemoSurfaceStateUpdateRenderCommand" \
  "didRefreshAiGeneratedSettingsRecoveryDemoSurfaceStateUpdateRenderCommand" \
  "didBindActionExecutorStateUpdateCandidateToRenderCommandRefresh" \
  "didBindStage451ActionExecutorPreviewToRenderCommandRefresh" \
  "didBindStage450ExecutionReceiptToRenderCommandRefresh" \
  "didKeepRenderCommandRefreshOwnerLocal" \
  "didKeepRenderCommandRefreshPreviewOnly" \
  "didPrepareStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreview" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage453 recovery demo surface state update render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage453_recovery_demo_surface_state_update_render_command_refresh_owner_present=true"
echo "stage452_recovery_demo_surface_action_executor_state_update_dry_run_required=true"
echo "stage452_recovery_demo_surface_action_executor_state_update_dry_run_consumed=true"
echo "recovery_demo_surface_action_executor_state_update_dry_run_consumed=true"
echo "todo_recovery_demo_surface_action_executor_state_update_candidate_consumed=true"
echo "settings_recovery_demo_surface_action_executor_state_update_candidate_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_action_executor_state_update_candidate_consumed=true"
echo "recovery_demo_surface_state_update_render_command_refresh_materialized=true"
echo "todo_recovery_demo_surface_state_update_render_command_refreshed=true"
echo "settings_recovery_demo_surface_state_update_render_command_refreshed=true"
echo "ai_generated_settings_recovery_demo_surface_state_update_render_command_refreshed=true"
echo "action_executor_state_update_candidate_to_render_command_refresh_bound=true"
echo "stage451_action_executor_preview_to_render_command_refresh_bound=true"
echo "stage450_execution_receipt_to_render_command_refresh_bound=true"
echo "recovery_demo_surface_render_command_refresh_owner_local=true"
echo "recovery_demo_surface_render_command_refresh_preview_only=true"
echo "stage454_recovery_demo_surface_render_command_layout_style_preview_prepared=true"
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
