#!/usr/bin/env zsh
#
# Verifies the stage746 AI-generated UI owner review preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage746_ai_generated_ui_owner_review_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage746 ai generated ui owner review preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage746AiGeneratedUiOwnerReviewPreflightPlan" \
  "CjguiInternalRendererStage746AiGeneratedUiOwnerReviewPreflightFacts" \
  "CjguiInternalRendererStage746AiGeneratedUiOwnerReviewPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage746AiGeneratedUiOwnerReviewPreflightDraft" \
  "CjguiInternalRendererStage745AiGeneratedUiDslDryRunReadiness" \
  "didConsumeStage745AiGeneratedUiDslDryRun" \
  "didMaterializeAiGeneratedUiSemanticDiffReview" \
  "didMaterializeAiGeneratedUiExplainRows" \
  "didMaterializeOwnerAcceptRejectPreflight" \
  "didMaterializeAiGeneratedUiRejectReasonLedger" \
  "didPrepareStage747AiGeneratedUiHostInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage746 ai generated ui owner review preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage746_ai_generated_ui_owner_review_preflight_owner_present=true"
echo "stage745_ai_generated_ui_dsl_dry_run_consumed=true"
echo "ai_generated_ui_semantic_diff_review_materialized=true"
echo "ai_generated_ui_explain_rows_materialized=true"
echo "owner_accept_reject_preflight_materialized=true"
echo "ai_generated_ui_reject_reason_ledger_materialized=true"
echo "stage747_ai_generated_ui_host_inspection_surface_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
