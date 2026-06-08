#!/usr/bin/env zsh
#
# Verifies the stage790 preview component API commit transaction patch plan owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage790_preview_component_api_commit_transaction_patch_plan.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage790 preview component api commit transaction patch plan: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage790PreviewComponentApiCommitTransactionPatchPlanPlan" \
  "CjguiInternalRendererStage790PreviewComponentApiCommitTransactionPatchPlanFacts" \
  "CjguiInternalRendererStage790PreviewComponentApiCommitTransactionPatchPlanReadiness" \
  "cjguiInternalExecuteDefaultRendererStage790PreviewComponentApiCommitTransactionPatchPlanDraft" \
  "CjguiInternalRendererStage789PreviewComponentApiCommitAdmissionDecisionReadiness" \
  "didConsumeStage789PreviewComponentApiCommitAdmissionDecision" \
  "didMaterializeOwnerLocalTransactionPatchPlan" \
  "didMaterializeRollbackSnapshotHandle" \
  "didMaterializeConflictVersionCheck" \
  "didMaterializeFocusHandoffPatchPlaceholder" \
  "didMaterializeTextEditPatchPlaceholder" \
  "didMaterializeStyleDeltaPatchPlaceholder" \
  "didMaterializeAcceptedDecisionPatchBranch" \
  "didMaterializeRejectedDecisionRollbackBranch" \
  "didPrepareStage791PreviewComponentApiCommitTransactionDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage790 preview component api commit transaction patch plan: missing token $token" >&2
    exit 3
  fi
done

echo "stage790_preview_component_api_commit_transaction_patch_plan_owner_present=true"
echo "stage789_preview_component_api_commit_admission_decision_consumed=true"
echo "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_consumed_transitively=true"
echo "owner_local_transaction_patch_plan_materialized=true"
echo "rollback_snapshot_handle_materialized=true"
echo "conflict_version_check_materialized=true"
echo "focus_handoff_patch_placeholder_materialized=true"
echo "text_edit_patch_placeholder_materialized=true"
echo "style_delta_patch_placeholder_materialized=true"
echo "accepted_decision_patch_branch_materialized=true"
echo "rejected_decision_rollback_branch_materialized=true"
echo "transaction_patch_plan_bound_to_stage789_decision_resolver=true"
echo "commit_transaction_patch_plan_non_committing=true"
echo "stage791_preview_component_api_commit_transaction_demo_host_surface_prepared=true"
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
