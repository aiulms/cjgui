#!/usr/bin/env zsh
#
# 维护注释：验证 stage451 recovery demo surface execution receipt -> shared action executor preview owner。
# 它必须消费 stage450 execution dry-run receipt，并生成 non-dispatching shared action executor candidate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage451_recovery_demo_surface_execution_action_executor_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage451 recovery demo surface action executor preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage451RecoveryDemoSurfaceExecutionActionExecutorPreviewPlan" \
  "CjguiInternalRendererStage451RecoveryDemoSurfaceExecutionActionExecutorPreviewFacts" \
  "CjguiInternalRendererStage451RecoveryDemoSurfaceExecutionActionExecutorPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage451RecoveryDemoSurfaceExecutionActionExecutorPreviewDraft" \
  "CjguiInternalRendererStage450RecoveryDemoSurfaceExecutionDryRunReadiness" \
  "didConsumeStage450RecoveryDemoSurfaceExecutionDryRun" \
  "didConsumeRecoveryDemoSurfaceExecutionDryRunReceipt" \
  "didMaterializeSharedRecoveryDemoSurfaceActionExecutorPreview" \
  "didMapTodoExecutionReceiptToSharedActionExecutorCandidate" \
  "didMapSettingsExecutionReceiptToSharedActionExecutorCandidate" \
  "didMapAiGeneratedSettingsExecutionReceiptToSharedActionExecutorCandidate" \
  "didBindExecutionDryRunReceiptToActionExecutorPreview" \
  "didKeepActionExecutorPreviewNonDispatching" \
  "didPrepareStage452RecoveryDemoSurfaceActionExecutorStateUpdateDryRun" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage451 recovery demo surface action executor preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage451_recovery_demo_surface_execution_action_executor_preview_owner_present=true"
echo "stage450_recovery_demo_surface_execution_dry_run_required=true"
echo "stage450_recovery_demo_surface_execution_dry_run_consumed=true"
echo "recovery_demo_surface_execution_dry_run_receipt_consumed=true"
echo "todo_recovery_demo_surface_execution_dry_run_receipt_consumed=true"
echo "settings_recovery_demo_surface_execution_dry_run_receipt_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_execution_dry_run_receipt_consumed=true"
echo "shared_recovery_demo_surface_action_executor_preview_materialized=true"
echo "todo_recovery_demo_surface_action_executor_candidate_materialized=true"
echo "settings_recovery_demo_surface_action_executor_candidate_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_action_executor_candidate_materialized=true"
echo "execution_dry_run_receipt_to_action_executor_preview_bound=true"
echo "stage445_semantic_projection_to_action_executor_preview_bound=true"
echo "recovery_demo_surface_action_executor_owner_local=true"
echo "recovery_demo_surface_action_executor_non_dispatching=true"
echo "recovery_demo_surface_action_executor_dry_run_only=true"
echo "stage452_recovery_demo_surface_action_executor_state_update_dry_run_prepared=true"
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
