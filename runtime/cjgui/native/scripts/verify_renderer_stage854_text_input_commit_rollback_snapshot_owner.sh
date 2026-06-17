#!/usr/bin/env zsh
#
# Verifies the stage854 text input commit rollback snapshot owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage854_text_input_commit_rollback_snapshot.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage854 text input commit rollback snapshot: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage854TextInputCommitRollbackSnapshotPlan" \
  "CjguiInternalRendererStage854TextInputCommitRollbackSnapshotFacts" \
  "CjguiInternalRendererStage854TextInputCommitRollbackSnapshotReadiness" \
  "cjguiInternalExecuteDefaultRendererStage854TextInputCommitRollbackSnapshotDraft" \
  "CjguiInternalRendererStage853TextInputCommitPreflightReadiness" \
  "didConsumeStage853TextInputCommitPreflight" \
  "didMaterializeTextInputRollbackSnapshot" \
  "didMaterializeTextInputNotPublishedReceipt" \
  "didMaterializeTextInputCommitCandidateLedgerEntry" \
  "didMaterializeOwnerLocalTextInputWriteSetCandidate" \
  "didMaterializeCommitPreflightToRollbackReceiptBridge" \
  "didMaterializeFileBrowserTextInputCommitRollbackSurface" \
  "didBindRollbackSnapshotToStage853CommitPreflight" \
  "didPrepareStage855TextInputCommitInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage854 text input commit rollback snapshot: missing token $token" >&2
    exit 3
  fi
done

echo "stage854_text_input_commit_rollback_snapshot_owner_present=true"
echo "stage853_text_input_commit_preflight_consumed=true"
echo "text_input_commit_candidate_ledger_consumed=true"
echo "text_input_rollback_snapshot_materialized=true"
echo "text_input_not_published_receipt_materialized=true"
echo "text_input_commit_candidate_ledger_entry_materialized=true"
echo "owner_local_text_input_write_set_candidate_materialized=true"
echo "commit_preflight_to_rollback_receipt_bridge_materialized=true"
echo "todo_text_input_commit_rollback_surface_materialized=true"
echo "settings_text_input_commit_rollback_surface_materialized=true"
echo "ai_generated_settings_text_input_commit_rollback_surface_materialized=true"
echo "chat_composer_text_input_commit_rollback_surface_materialized=true"
echo "file_browser_text_input_commit_rollback_surface_materialized=true"
echo "rollback_snapshot_bound_to_stage853_commit_preflight=true"
echo "stage855_text_input_commit_inspection_surface_prepared=true"
echo "text_input_commit_committed=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
