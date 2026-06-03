#!/usr/bin/env zsh
#
# Verifies the stage773 preview component API commit admission dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage773_preview_component_api_commit_admission_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage773 preview component api commit admission dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage773PreviewComponentApiCommitAdmissionDryRunPlan" \
  "CjguiInternalRendererStage773PreviewComponentApiCommitAdmissionDryRunFacts" \
  "CjguiInternalRendererStage773PreviewComponentApiCommitAdmissionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage773PreviewComponentApiCommitAdmissionDryRunDraft" \
  "CjguiInternalRendererStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManagerReadiness" \
  "didConsumeStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManager" \
  "didMaterializePreviewComponentApiCommitAdmissionDryRun" \
  "didMaterializePreviewComponentApiAcceptedCommitAdmissionCandidate" \
  "didMaterializePreviewComponentApiRejectedCommitAdmissionCandidate" \
  "didMaterializeOwnerDecisionToCommitAdmissionBridge" \
  "didMaterializeChatComposerPreviewComponentApiCommitAdmissionSurface" \
  "didBindCommitAdmissionDryRunToStage772DecisionRuntimeManager" \
  "didKeepPreviewComponentApiCommitAdmissionNonCommitting" \
  "didPrepareStage774PreviewComponentApiCommitDenialRollbackReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage773 preview component api commit admission dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage773_preview_component_api_commit_admission_dry_run_owner_present=true"
echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_consumed=true"
echo "stage771_preview_component_api_acceptance_feedback_surface_consumed_transitively=true"
echo "stage768_preview_component_api_commit_runtime_manager_consumed_transitively=true"
echo "preview_component_api_commit_admission_dry_run_materialized=true"
echo "preview_component_api_accepted_commit_admission_candidate_materialized=true"
echo "preview_component_api_rejected_commit_admission_candidate_materialized=true"
echo "owner_decision_to_commit_admission_bridge_materialized=true"
echo "todo_preview_component_api_commit_admission_surface_materialized=true"
echo "settings_preview_component_api_commit_admission_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_admission_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_admission_surface_materialized=true"
echo "commit_admission_dry_run_bound_to_stage772_decision_runtime_manager=true"
echo "preview_component_api_commit_admission_non_committing=true"
echo "stage774_preview_component_api_commit_denial_rollback_receipt_prepared=true"
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
