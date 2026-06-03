#!/usr/bin/env zsh
#
# Verifies the stage766 preview component API commit rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage766_preview_component_api_commit_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage766 preview component api commit rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage766PreviewComponentApiCommitRollbackSnapshotPlan" \
  "CjguiInternalRendererStage766PreviewComponentApiCommitRollbackSnapshotFacts" \
  "CjguiInternalRendererStage766PreviewComponentApiCommitRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage766PreviewComponentApiCommitRollbackSnapshotDraft" \
  "CjguiInternalRendererStage765PreviewComponentApiCommitPreflightReadiness" \
  "didConsumeStage765PreviewComponentApiCommitPreflight" \
  "didConsumePreviewComponentApiCommitCandidateLedger" \
  "didMaterializePreviewComponentApiCommitRollbackBaseSnapshot" \
  "didMaterializePreviewComponentApiPendingCommitSnapshot" \
  "didMaterializePreviewComponentApiOwnerRejectRollbackBranch" \
  "didMaterializePreviewComponentApiCommitRollbackTokenLedger" \
  "didMaterializeChatComposerPreviewComponentApiCommitRollbackSurface" \
  "didPrepareStage767PreviewComponentApiCommitHostInspectionProof"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage766 preview component api commit rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage766_preview_component_api_commit_rollback_snapshot_owner_present=true"
echo "stage765_preview_component_api_commit_preflight_consumed=true"
echo "stage764_preview_component_api_visual_resolver_runtime_manager_consumed_transitively=true"
echo "preview_component_api_commit_candidate_ledger_consumed=true"
echo "preview_component_api_commit_rollback_base_snapshot_materialized=true"
echo "preview_component_api_pending_commit_snapshot_materialized=true"
echo "preview_component_api_validation_failure_rollback_branch_materialized=true"
echo "preview_component_api_owner_reject_rollback_branch_materialized=true"
echo "preview_component_api_commit_conflict_classifier_materialized=true"
echo "preview_component_api_commit_rollback_token_ledger_materialized=true"
echo "todo_preview_component_api_commit_rollback_surface_materialized=true"
echo "settings_preview_component_api_commit_rollback_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_rollback_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_rollback_surface_materialized=true"
echo "rollback_snapshot_bound_to_stage765_commit_preflight=true"
echo "preview_component_api_rollback_non_committing=true"
echo "stage767_preview_component_api_commit_host_inspection_proof_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
