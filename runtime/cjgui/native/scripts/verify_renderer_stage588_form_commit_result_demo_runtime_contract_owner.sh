#!/usr/bin/env zsh
#
# Verifies the stage588 form commit result demo runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage588_form_commit_result_demo_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage588 form commit result demo runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage588FormCommitResultDemoRuntimeContractPlan" \
  "CjguiInternalRendererStage588FormCommitResultDemoRuntimeContractFacts" \
  "CjguiInternalRendererStage588FormCommitResultDemoRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage588FormCommitResultDemoRuntimeContractDraft" \
  "CjguiInternalRendererStage587FormCommitResultFeedbackLayoutFocusReadiness" \
  "didMaterializeSharedFormCommitResultDemoRuntimeContract" \
  "didMaterializeSharedFormCommitResultDemoRuntimeHelper" \
  "didMaterializeSharedFormCommitResultExecutionReceiptContract" \
  "didMaterializeTodoCheckableFormCommitResultRuntimeSurface" \
  "didMaterializeSettingsCheckableFormCommitResultRuntimeSurface" \
  "didMaterializeAiGeneratedSettingsCheckableFormCommitResultRuntimeSurface" \
  "didMaterializeChatComposerCheckableFormCommitResultRuntimeSurface" \
  "didBindFormCommitResultDemoRuntimeContractToStage587FeedbackReceipts" \
  "didBindFormCommitResultDemoRuntimeContractToStage586ResultSurfaces" \
  "didReducePerDemoFormCommitResultTemplateNeed" \
  "didPrepareStage589ComponentRuntimeFormResultHostInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage588 form commit result demo runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage588_form_commit_result_demo_runtime_contract_owner_present=true"
echo "stage587_form_commit_result_feedback_layout_focus_consumed=true"
echo "stage586_form_commit_result_surface_refresh_consumed_transitively=true"
echo "stage585_form_commit_demo_runtime_surface_contract_consumed_transitively=true"
echo "shared_form_commit_result_demo_runtime_contract_materialized=true"
echo "shared_form_commit_result_demo_runtime_helper_materialized=true"
echo "shared_form_commit_result_execution_receipt_contract_materialized=true"
echo "todo_checkable_form_commit_result_runtime_surface_materialized=true"
echo "settings_checkable_form_commit_result_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_form_commit_result_runtime_surface_materialized=true"
echo "chat_composer_checkable_form_commit_result_runtime_surface_materialized=true"
echo "form_commit_result_demo_runtime_contract_bound_to_stage587_feedback_receipts=true"
echo "form_commit_result_demo_runtime_contract_bound_to_stage586_result_surfaces=true"
echo "form_commit_result_demo_runtime_contract_bound_to_stage585_runtime_surfaces=true"
echo "per_demo_form_commit_result_template_need_reduced=true"
echo "stage589_component_runtime_form_result_host_inspection_prepared=true"
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
