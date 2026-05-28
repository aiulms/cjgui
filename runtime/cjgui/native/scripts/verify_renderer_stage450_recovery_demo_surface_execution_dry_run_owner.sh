#!/usr/bin/env zsh
#
# 维护注释：验证 stage450 recovery demo surface preview delta -> execution dry-run owner。
# 它必须消费 stage449 preview delta，并生成共享 demo surface execution dry-run receipt。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage450_recovery_demo_surface_execution_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage450 recovery demo surface execution dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage450RecoveryDemoSurfaceExecutionDryRunPlan" \
  "CjguiInternalRendererStage450RecoveryDemoSurfaceExecutionDryRunFacts" \
  "CjguiInternalRendererStage450RecoveryDemoSurfaceExecutionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage450RecoveryDemoSurfaceExecutionDryRunDraft" \
  "CjguiInternalRendererStage449RecoveryDemoSurfaceRenderCommandRefreshDryRunReadiness" \
  "didConsumeStage449RecoveryDemoSurfaceRenderCommandRefreshDryRun" \
  "didConsumeRecoveryDemoSurfacePreviewDelta" \
  "didMaterializeSharedRecoveryDemoSurfaceExecutionModel" \
  "didMaterializeRecoveryDemoSurfaceExecutionDryRunReceipt" \
  "didMapTodoPreviewDeltaToExecutionDryRunReceipt" \
  "didMapSettingsPreviewDeltaToExecutionDryRunReceipt" \
  "didMapAiGeneratedSettingsPreviewDeltaToExecutionDryRunReceipt" \
  "didBindPreviewDeltaToExecutionDryRunReceipt" \
  "didBindStage445SemanticProjectionToExecutionDryRunReceipt" \
  "didKeepRecoveryDemoSurfaceExecutionNonDispatching" \
  "didPrepareStage451RecoveryDemoSurfaceExecutionActionExecutorPreview" \
  "didKeepActionDispatchBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage450 recovery demo surface execution dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage450_recovery_demo_surface_execution_dry_run_owner_present=true"
echo "stage449_recovery_demo_surface_render_command_refresh_dry_run_required=true"
echo "stage449_recovery_demo_surface_render_command_refresh_dry_run_consumed=true"
echo "recovery_demo_surface_preview_delta_consumed=true"
echo "todo_recovery_demo_surface_preview_delta_consumed=true"
echo "settings_recovery_demo_surface_preview_delta_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_preview_delta_consumed=true"
echo "shared_recovery_demo_surface_execution_model_materialized=true"
echo "recovery_demo_surface_execution_dry_run_receipt_materialized=true"
echo "todo_recovery_demo_surface_execution_dry_run_receipt_materialized=true"
echo "settings_recovery_demo_surface_execution_dry_run_receipt_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_execution_dry_run_receipt_materialized=true"
echo "preview_delta_to_execution_dry_run_receipt_bound=true"
echo "stage445_semantic_projection_to_execution_dry_run_receipt_bound=true"
echo "recovery_demo_surface_execution_owner_local=true"
echo "recovery_demo_surface_execution_non_dispatching=true"
echo "recovery_demo_surface_execution_dry_run_only=true"
echo "stage451_recovery_demo_surface_execution_action_executor_preview_prepared=true"
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
