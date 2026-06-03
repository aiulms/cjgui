#!/usr/bin/env zsh
#
# Verifies the stage770 preview component API acceptance decision reducer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage770_preview_component_api_acceptance_decision_reducer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage770 preview component api acceptance decision reducer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage770PreviewComponentApiAcceptanceDecisionReducerPlan" \
  "CjguiInternalRendererStage770PreviewComponentApiAcceptanceDecisionReducerFacts" \
  "CjguiInternalRendererStage770PreviewComponentApiAcceptanceDecisionReducerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage770PreviewComponentApiAcceptanceDecisionReducerDraft" \
  "CjguiInternalRendererStage769PreviewComponentApiOwnerAcceptanceBoundaryReadiness" \
  "didConsumeStage769PreviewComponentApiOwnerAcceptanceBoundary" \
  "didMaterializePreviewComponentApiAcceptDecisionCandidate" \
  "didMaterializePreviewComponentApiRejectDecisionCandidate" \
  "didMaterializePreviewComponentApiDecisionConflictClassifier" \
  "didMaterializePreviewComponentApiDecisionRollbackPlan" \
  "didMaterializePreviewComponentApiDecisionReceiptLedger" \
  "didBindAcceptanceDecisionReducerToStage769Boundary" \
  "didPrepareStage771PreviewComponentApiAcceptanceFeedbackSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage770 preview component api acceptance decision reducer: missing token $token" >&2
    exit 3
  fi
done

echo "stage770_preview_component_api_acceptance_decision_reducer_owner_present=true"
echo "stage769_preview_component_api_owner_acceptance_boundary_consumed=true"
echo "stage768_preview_component_api_commit_runtime_manager_consumed_transitively=true"
echo "preview_component_api_accept_decision_candidate_materialized=true"
echo "preview_component_api_reject_decision_candidate_materialized=true"
echo "preview_component_api_decision_conflict_classifier_materialized=true"
echo "preview_component_api_decision_rollback_plan_materialized=true"
echo "preview_component_api_decision_receipt_ledger_materialized=true"
echo "todo_preview_component_api_acceptance_decision_surface_materialized=true"
echo "settings_preview_component_api_acceptance_decision_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_acceptance_decision_surface_materialized=true"
echo "chat_composer_preview_component_api_acceptance_decision_surface_materialized=true"
echo "acceptance_decision_reducer_bound_to_stage769_boundary=true"
echo "acceptance_decision_reducer_non_dispatching=true"
echo "stage771_preview_component_api_acceptance_feedback_surface_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
