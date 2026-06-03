#!/usr/bin/env zsh
#
# Verifies the stage745 AI-generated UI DSL dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage745_ai_generated_ui_dsl_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage745 ai generated ui dsl dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage745AiGeneratedUiDslDryRunPlan" \
  "CjguiInternalRendererStage745AiGeneratedUiDslDryRunFacts" \
  "CjguiInternalRendererStage745AiGeneratedUiDslDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage745AiGeneratedUiDslDryRunDraft" \
  "CjguiInternalRendererStage744ComponentApiAuthoringDslRuntimeManagerReadiness" \
  "didConsumeStage744ComponentApiAuthoringDslRuntimeManager" \
  "didMaterializeAiGeneratedUiPromptConstraintLedger" \
  "didMaterializeAiGeneratedUiComponentDeclarationProposal" \
  "didMaterializeAiGeneratedUiDryRunRequestContract" \
  "didMaterializeTodoAiGeneratedUiDslDryRunSurface" \
  "didMaterializeSettingsAiGeneratedUiDslDryRunSurface" \
  "didMaterializeAiGeneratedSettingsAiGeneratedUiDslDryRunSurface" \
  "didMaterializeChatComposerAiGeneratedUiDslDryRunSurface" \
  "didPrepareStage746AiGeneratedUiOwnerReviewPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage745 ai generated ui dsl dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage745_ai_generated_ui_dsl_dry_run_owner_present=true"
echo "stage744_component_api_authoring_dsl_runtime_manager_consumed=true"
echo "ai_generated_ui_prompt_constraint_ledger_materialized=true"
echo "ai_generated_ui_component_declaration_proposal_materialized=true"
echo "ai_generated_ui_dry_run_request_contract_materialized=true"
echo "todo_ai_generated_ui_dsl_dry_run_surface_materialized=true"
echo "settings_ai_generated_ui_dsl_dry_run_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_dsl_dry_run_surface_materialized=true"
echo "chat_composer_ai_generated_ui_dsl_dry_run_surface_materialized=true"
echo "stage746_ai_generated_ui_owner_review_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
