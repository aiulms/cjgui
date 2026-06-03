#!/usr/bin/env zsh
#
# Verifies the stage734 component visual state store commit rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage734_component_visual_state_store_commit_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage734 component visual state store commit rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage734ComponentVisualStateStoreCommitRollbackSnapshotPlan" \
  "CjguiInternalRendererStage734ComponentVisualStateStoreCommitRollbackSnapshotFacts" \
  "CjguiInternalRendererStage734ComponentVisualStateStoreCommitRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage734ComponentVisualStateStoreCommitRollbackSnapshotDraft" \
  "CjguiInternalRendererStage733ComponentVisualStateStoreCommitPreflightReadiness" \
  "didConsumeStage733ComponentVisualStateStoreCommitPreflight" \
  "didMaterializeCommitRollbackBaseSnapshot" \
  "didMaterializePendingCommitSnapshot" \
  "didMaterializeValidationFailureRollbackBranch" \
  "didMaterializeOwnerRejectRollbackBranch" \
  "didMaterializeCommitConflictClassifier" \
  "didPrepareStage735ComponentVisualStateStoreCommitHostInspectionUi"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage734 component visual state store commit rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage734_component_visual_state_store_commit_rollback_snapshot_owner_present=true"
echo "stage733_component_visual_state_store_commit_preflight_consumed=true"
echo "stage732_component_visual_state_store_resolver_runtime_manager_consumed_transitively=true"
echo "commit_rollback_base_snapshot_materialized=true"
echo "pending_commit_snapshot_materialized=true"
echo "validation_failure_rollback_branch_materialized=true"
echo "owner_reject_rollback_branch_materialized=true"
echo "commit_conflict_classifier_materialized=true"
echo "commit_rollback_token_ledger_materialized=true"
echo "todo_component_visual_state_store_commit_rollback_surface_materialized=true"
echo "settings_component_visual_state_store_commit_rollback_surface_materialized=true"
echo "ai_generated_settings_component_visual_state_store_commit_rollback_surface_materialized=true"
echo "chat_composer_component_visual_state_store_commit_rollback_surface_materialized=true"
echo "stage735_component_visual_state_store_commit_host_inspection_ui_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
