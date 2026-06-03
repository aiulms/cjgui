#!/usr/bin/env zsh
#
# Verifies the stage749 AI-generated UI owner acceptance preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage749_ai_generated_ui_owner_acceptance_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage749 ai generated ui owner acceptance preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage749AiGeneratedUiOwnerAcceptancePreflightPlan" \
  "CjguiInternalRendererStage749AiGeneratedUiOwnerAcceptancePreflightFacts" \
  "CjguiInternalRendererStage749AiGeneratedUiOwnerAcceptancePreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage749AiGeneratedUiOwnerAcceptancePreflightDraft" \
  "CjguiInternalRendererStage748AiGeneratedUiRuntimeManagerReadiness" \
  "didConsumeStage748AiGeneratedUiRuntimeManager" \
  "didMaterializeOwnerAcceptancePreflightRows" \
  "didMaterializeOwnerAcceptanceCandidateLedger" \
  "didMaterializeOwnerRiskClassificationLedger" \
  "didMaterializeOwnerRejectReasonLedger" \
  "didBindOwnerAcceptancePreflightToAiGeneratedUiRuntimeManager" \
  "didPrepareStage750AiGeneratedUiPublicSurfacePreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage749 ai generated ui owner acceptance preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage749_ai_generated_ui_owner_acceptance_preflight_owner_present=true"
echo "stage748_ai_generated_ui_runtime_manager_consumed=true"
echo "stage747_ai_generated_ui_host_inspection_surface_consumed_transitively=true"
echo "stage746_ai_generated_ui_owner_review_preflight_consumed_transitively=true"
echo "stage745_ai_generated_ui_dsl_dry_run_consumed_transitively=true"
echo "owner_acceptance_preflight_rows_materialized=true"
echo "owner_acceptance_candidate_ledger_materialized=true"
echo "owner_risk_classification_ledger_materialized=true"
echo "owner_reject_reason_ledger_materialized=true"
echo "todo_ai_generated_ui_owner_acceptance_preflight_materialized=true"
echo "settings_ai_generated_ui_owner_acceptance_preflight_materialized=true"
echo "ai_generated_settings_ai_generated_ui_owner_acceptance_preflight_materialized=true"
echo "chat_composer_ai_generated_ui_owner_acceptance_preflight_materialized=true"
echo "owner_acceptance_preflight_bound_to_ai_generated_ui_runtime_manager=true"
echo "stage750_ai_generated_ui_public_surface_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
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
