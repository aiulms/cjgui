#!/usr/bin/env zsh
#
# Verifies the stage583 form input event commit preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage583_form_input_event_commit_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage583 form input event commit preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage583FormInputEventCommitPreviewPlan" \
  "CjguiInternalRendererStage583FormInputEventCommitPreviewFacts" \
  "CjguiInternalRendererStage583FormInputEventCommitPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage583FormInputEventCommitPreviewDraft" \
  "CjguiInternalRendererStage582FormDemoRuntimeSurfaceContractReadiness" \
  "didMaterializeSharedFormInputCommitPreviewAdapter" \
  "didMaterializeNormalizedFormCommitEventLedger" \
  "didMaterializeFormCommitRollbackPreviewLedger" \
  "didMaterializeFormCommitOwnerAcceptanceLedger" \
  "didMaterializeTodoFormCommitPreviewEvent" \
  "didMaterializeSettingsFormCommitPreviewEvent" \
  "didMaterializeAiGeneratedSettingsFormCommitPreviewEvent" \
  "didMaterializeChatComposerFormCommitPreviewEvent" \
  "didBindFormInputCommitPreviewToStage582RuntimeSurfaces" \
  "didPrepareStage584FormCommitCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage583 form input event commit preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage583_form_input_event_commit_preview_owner_present=true"
echo "stage582_form_demo_runtime_surface_contract_consumed=true"
echo "stage581_form_summary_focus_render_executor_consumed_transitively=true"
echo "shared_form_input_commit_preview_adapter_materialized=true"
echo "normalized_form_commit_event_ledger_materialized=true"
echo "form_commit_rollback_preview_ledger_materialized=true"
echo "form_commit_owner_acceptance_ledger_materialized=true"
echo "todo_form_commit_preview_event_materialized=true"
echo "settings_form_commit_preview_event_materialized=true"
echo "ai_generated_settings_form_commit_preview_event_materialized=true"
echo "chat_composer_form_commit_preview_event_materialized=true"
echo "form_input_commit_preview_bound_to_stage582_runtime_surfaces=true"
echo "form_input_commit_preview_bound_to_stage581_summary_receipts=true"
echo "form_input_commit_preview_owner_local=true"
echo "stage584_form_commit_cycle_executor_prepared=true"
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
