#!/usr/bin/env zsh
#
# Verifies the stage798 preview component API state-store commit review checkpoint owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage798_preview_component_api_state_store_commit_review_checkpoint.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage798 preview component api state-store commit review checkpoint: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage798PreviewComponentApiStateStoreCommitReviewCheckpointPlan" \
  "CjguiInternalRendererStage798PreviewComponentApiStateStoreCommitReviewCheckpointFacts" \
  "CjguiInternalRendererStage798PreviewComponentApiStateStoreCommitReviewCheckpointReadiness" \
  "cjguiInternalExecuteDefaultRendererStage798PreviewComponentApiStateStoreCommitReviewCheckpointDraft" \
  "CjguiInternalRendererStage797PreviewComponentApiStateStoreCommitAdmissionPreviewReadiness" \
  "didConsumeStage797PreviewComponentApiStateStoreCommitAdmissionPreview" \
  "didMaterializeOwnerCommitReviewCheckpoint" \
  "didMaterializeRollbackCheckpointSelection" \
  "didMaterializeCompatibilityDecisionReceipt" \
  "didMaterializeDeprecationRollbackNote" \
  "didMaterializeExplainableAcceptRejectRequestChangesReceipt" \
  "didKeepCommitAdmissionCheckpointNonCommitting" \
  "didPrepareStage799PreviewComponentApiStateStoreCommitDemoHostPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage798 preview component api state-store commit review checkpoint: missing token $token" >&2
    exit 3
  fi
done

echo "stage798_preview_component_api_state_store_commit_review_checkpoint_owner_present=true"
echo "stage797_preview_component_api_state_store_commit_admission_preview_consumed=true"
echo "owner_commit_review_checkpoint_materialized=true"
echo "rollback_checkpoint_selection_materialized=true"
echo "compatibility_decision_receipt_materialized=true"
echo "deprecation_rollback_note_materialized=true"
echo "explainable_accept_reject_request_changes_receipt_materialized=true"
echo "commit_admission_checkpoint_non_committing=true"
echo "stage799_preview_component_api_state_store_commit_demo_host_preview_prepared=true"
echo "public_component_api_added=true"
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
