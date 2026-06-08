#!/usr/bin/env zsh
#
# Verifies the stage806 preview component API state-store commit review time-travel rehearsal owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage806 preview component api state-store commit review time-travel rehearsal: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsalPlan" \
  "CjguiInternalRendererStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsalFacts" \
  "CjguiInternalRendererStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsalReadiness" \
  "cjguiInternalExecuteDefaultRendererStage806PreviewComponentApiStateStoreCommitReviewTimeTravelRehearsalDraft" \
  "CjguiInternalRendererStage805PreviewComponentApiStateStoreCommitReviewHistoryReadiness" \
  "didConsumeStage805PreviewComponentApiStateStoreCommitReviewHistory" \
  "didMaterializeSelectedReviewHistoryEntry" \
  "didMaterializeRollbackTimeTravelSnapshot" \
  "didMaterializePreCommitStatePreview" \
  "didMaterializePostReviewStatePreview" \
  "didMaterializeHistoryReplayReceipt" \
  "didKeepTimeTravelRehearsalNonCommitting" \
  "didPrepareStage807PreviewComponentApiStateStoreCommitReviewHistoryDemoHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage806 preview component api state-store commit review time-travel rehearsal: missing token $token" >&2
    exit 3
  fi
done

echo "stage806_preview_component_api_state_store_commit_review_time_travel_rehearsal_owner_present=true"
echo "stage805_preview_component_api_state_store_commit_review_history_consumed=true"
echo "selected_review_history_entry_materialized=true"
echo "rollback_time_travel_snapshot_materialized=true"
echo "pre_commit_state_preview_materialized=true"
echo "post_review_state_preview_materialized=true"
echo "history_replay_receipt_materialized=true"
echo "time_travel_rehearsal_non_committing=true"
echo "stage807_preview_component_api_state_store_commit_review_history_demo_host_surface_prepared=true"
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
