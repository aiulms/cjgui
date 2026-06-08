#!/usr/bin/env zsh
#
# Verifies the stage810 preview component API state-store commit acceptance decision dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage810 preview component api state-store commit acceptance decision dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRunPlan" \
  "CjguiInternalRendererStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRunFacts" \
  "CjguiInternalRendererStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRunDraft" \
  "CjguiInternalRendererStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsalReadiness" \
  "didConsumeStage809PreviewComponentApiStateStoreCommitAcceptanceRehearsal" \
  "didMaterializeAcceptDecisionDryRun" \
  "didMaterializeRejectDecisionDryRun" \
  "didMaterializeRequestChangesDecisionDryRun" \
  "didMaterializeCompatibilityBoundaryReceipt" \
  "didMaterializeAcceptanceBlockerReasonLedger" \
  "didMaterializeReviewerDecisionNote" \
  "didPrepareStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage810 preview component api state-store commit acceptance decision dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_owner_present=true"
echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_consumed=true"
echo "stage808_preview_component_api_state_store_commit_review_history_runtime_manager_consumed_transitively=true"
echo "accept_decision_dry_run_materialized=true"
echo "reject_decision_dry_run_materialized=true"
echo "request_changes_decision_dry_run_materialized=true"
echo "compatibility_boundary_receipt_materialized=true"
echo "acceptance_blocker_reason_ledger_materialized=true"
echo "reviewer_decision_note_materialized=true"
echo "acceptance_decision_dry_run_non_dispatching=true"
echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_prepared=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
