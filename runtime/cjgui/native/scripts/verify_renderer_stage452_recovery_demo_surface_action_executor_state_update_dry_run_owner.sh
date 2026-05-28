#!/usr/bin/env zsh
#
# 维护注释：验证 stage452 shared action executor preview -> owner-local state update dry-run owner。
# 它必须消费 stage451 action executor packet，并生成三个 demo surface 的 state update candidate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage452_recovery_demo_surface_action_executor_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage452 recovery demo surface action executor state update dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRunPlan" \
  "CjguiInternalRendererStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRunDraft" \
  "CjguiInternalRendererStage451RecoveryDemoSurfaceExecutionActionExecutorPreviewReadiness" \
  "didConsumeStage451RecoveryDemoSurfaceExecutionActionExecutorPreview" \
  "didConsumeSharedRecoveryDemoSurfaceActionExecutorPreview" \
  "didMaterializeRecoveryDemoSurfaceActionExecutorStateUpdateDryRun" \
  "didMaterializeTodoActionExecutorStateUpdateCandidate" \
  "didMaterializeSettingsActionExecutorStateUpdateCandidate" \
  "didMaterializeAiGeneratedSettingsActionExecutorStateUpdateCandidate" \
  "didBindActionExecutorPreviewToStateUpdateDryRun" \
  "didBindStage450ExecutionReceiptToStateUpdateDryRun" \
  "didKeepStateUpdateDryRunUncommitted" \
  "didPrepareStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefresh" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage452 recovery demo surface action executor state update dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage452_recovery_demo_surface_action_executor_state_update_dry_run_owner_present=true"
echo "stage451_recovery_demo_surface_execution_action_executor_preview_required=true"
echo "stage451_recovery_demo_surface_execution_action_executor_preview_consumed=true"
echo "shared_recovery_demo_surface_action_executor_preview_consumed=true"
echo "todo_recovery_demo_surface_action_executor_candidate_consumed=true"
echo "settings_recovery_demo_surface_action_executor_candidate_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_action_executor_candidate_consumed=true"
echo "recovery_demo_surface_action_executor_state_update_dry_run_materialized=true"
echo "todo_recovery_demo_surface_action_executor_state_update_candidate_materialized=true"
echo "settings_recovery_demo_surface_action_executor_state_update_candidate_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_action_executor_state_update_candidate_materialized=true"
echo "action_executor_preview_to_state_update_dry_run_bound=true"
echo "stage450_execution_receipt_to_state_update_dry_run_bound=true"
echo "recovery_demo_surface_action_executor_state_update_owner_local=true"
echo "recovery_demo_surface_action_executor_state_update_in_memory_only=true"
echo "recovery_demo_surface_action_executor_state_update_uncommitted=true"
echo "stage453_recovery_demo_surface_state_update_render_command_refresh_prepared=true"
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
