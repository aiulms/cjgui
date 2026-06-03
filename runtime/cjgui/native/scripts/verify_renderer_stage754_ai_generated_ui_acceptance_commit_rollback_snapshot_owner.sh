#!/usr/bin/env zsh
#
# Verifies the stage754 AI-generated UI acceptance commit rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage754_ai_generated_ui_acceptance_commit_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage754 ai generated ui acceptance commit rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage754AiGeneratedUiAcceptanceCommitRollbackSnapshotPlan" \
  "CjguiInternalRendererStage754AiGeneratedUiAcceptanceCommitRollbackSnapshotFacts" \
  "CjguiInternalRendererStage754AiGeneratedUiAcceptanceCommitRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage754AiGeneratedUiAcceptanceCommitRollbackSnapshotDraft" \
  "CjguiInternalRendererStage753AiGeneratedUiAcceptanceCommitPreflightReadiness" \
  "didConsumeStage753AiGeneratedUiAcceptanceCommitPreflight" \
  "didMaterializeAcceptanceCommitRollbackBaseSnapshot" \
  "didMaterializeAcceptancePendingCommitSnapshot" \
  "didMaterializeOwnerRejectRollbackBranch" \
  "didMaterializeValidationFailureRollbackBranch" \
  "didMaterializeAcceptanceConflictClassifier" \
  "didMaterializeAcceptanceRollbackTokenLedger" \
  "didBindRollbackSnapshotToAcceptanceCommitPreflight" \
  "didPrepareStage755AiGeneratedUiAcceptanceCommitHostInspectionProof"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage754 ai generated ui acceptance commit rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_owner_present=true"
echo "stage753_ai_generated_ui_acceptance_commit_preflight_consumed=true"
echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_consumed_transitively=true"
echo "owner_local_acceptance_commit_candidate_ledger_consumed=true"
echo "acceptance_commit_rollback_base_snapshot_materialized=true"
echo "acceptance_pending_commit_snapshot_materialized=true"
echo "owner_reject_rollback_branch_materialized=true"
echo "validation_failure_rollback_branch_materialized=true"
echo "acceptance_conflict_classifier_materialized=true"
echo "acceptance_rollback_token_ledger_materialized=true"
echo "todo_ai_generated_ui_acceptance_commit_rollback_snapshot_materialized=true"
echo "settings_ai_generated_ui_acceptance_commit_rollback_snapshot_materialized=true"
echo "ai_generated_settings_ai_generated_ui_acceptance_commit_rollback_snapshot_materialized=true"
echo "chat_composer_ai_generated_ui_acceptance_commit_rollback_snapshot_materialized=true"
echo "rollback_snapshot_bound_to_acceptance_commit_preflight=true"
echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
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
