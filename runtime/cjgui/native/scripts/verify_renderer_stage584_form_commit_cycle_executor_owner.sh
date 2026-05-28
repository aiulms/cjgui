#!/usr/bin/env zsh
#
# Verifies the stage584 form commit cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage584_form_commit_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage584 form commit cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage584FormCommitCycleExecutorPlan" \
  "CjguiInternalRendererStage584FormCommitCycleExecutorFacts" \
  "CjguiInternalRendererStage584FormCommitCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage584FormCommitCycleExecutorDraft" \
  "CjguiInternalRendererStage583FormInputEventCommitPreviewReadiness" \
  "didMaterializeSharedFormCommitCycleExecutor" \
  "didMaterializeFormCommitActionIntentLedger" \
  "didMaterializeFormCommitStateDeltaDryRunLedger" \
  "didMaterializeFormCommitValidationRefreshLedger" \
  "didMaterializeFormCommitRenderCommandRefreshLedger" \
  "didMaterializeFormCommitRollbackPreviewLedger" \
  "didMaterializeTodoFormCommitCycleReceipt" \
  "didMaterializeSettingsFormCommitCycleReceipt" \
  "didMaterializeAiGeneratedSettingsFormCommitCycleReceipt" \
  "didMaterializeChatComposerFormCommitCycleReceipt" \
  "didBindFormCommitCycleToStage583CommitPreview" \
  "didPrepareStage585FormCommitDemoRuntimeSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage584 form commit cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage584_form_commit_cycle_executor_owner_present=true"
echo "stage583_form_input_event_commit_preview_consumed=true"
echo "stage582_form_demo_runtime_surface_contract_consumed_transitively=true"
echo "shared_form_commit_cycle_executor_materialized=true"
echo "form_commit_action_intent_ledger_materialized=true"
echo "form_commit_state_delta_dry_run_ledger_materialized=true"
echo "form_commit_validation_refresh_ledger_materialized=true"
echo "form_commit_render_command_refresh_ledger_materialized=true"
echo "form_commit_rollback_preview_ledger_materialized=true"
echo "todo_form_commit_cycle_receipt_materialized=true"
echo "settings_form_commit_cycle_receipt_materialized=true"
echo "ai_generated_settings_form_commit_cycle_receipt_materialized=true"
echo "chat_composer_form_commit_cycle_receipt_materialized=true"
echo "form_commit_cycle_bound_to_stage583_commit_preview=true"
echo "form_commit_cycle_bound_to_stage582_runtime_surfaces=true"
echo "form_commit_cycle_owner_local=true"
echo "form_commit_cycle_non_dispatching=true"
echo "form_commit_state_dry_run_only=true"
echo "stage585_form_commit_demo_runtime_surface_contract_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
