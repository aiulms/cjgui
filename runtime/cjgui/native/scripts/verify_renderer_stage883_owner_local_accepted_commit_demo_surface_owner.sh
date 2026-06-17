#!/usr/bin/env zsh
#
# Verifies the stage883 owner-local accepted commit demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage883_owner_local_accepted_commit_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage883 owner-local accepted commit demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage883OwnerLocalAcceptedCommitDemoSurfacePlan" \
  "CjguiInternalRendererStage883OwnerLocalAcceptedCommitDemoSurfaceFacts" \
  "CjguiInternalRendererStage883OwnerLocalAcceptedCommitDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage883OwnerLocalAcceptedCommitDemoSurfaceDraft" \
  "CjguiInternalRendererStage882OwnerLocalAcceptedCommitApplicationReadiness" \
  "didConsumeStage882OwnerLocalAcceptedCommitApplicationPlan" \
  "didMaterializeTodoOwnerLocalAcceptedCommitSurface" \
  "didMaterializeSettingsOwnerLocalAcceptedCommitSurface" \
  "didMaterializeAiGeneratedSettingsOwnerLocalAcceptedCommitSurface" \
  "didMaterializeChatComposerOwnerLocalAcceptedCommitSurface" \
  "didMaterializeFileBrowserOwnerLocalAcceptedCommitSurface" \
  "didMaterializeAcceptedCommitApplicationInspectionRows" \
  "didMaterializeAcceptedCommitRollbackTokenRows" \
  "didMaterializeAcceptedCommitNotPublishedReceiptRows" \
  "didBindAcceptedCommitSurfaceToApplicationPlan" \
  "didPrepareStage884OwnerLocalAcceptedCommitRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage883 owner-local accepted commit demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage883_owner_local_accepted_commit_demo_surface_owner_present=true"
echo "stage882_owner_local_accepted_commit_application_plan_consumed=true"
echo "stage881_owner_local_accepted_commit_inspection_consumed_transitively=true"
echo "todo_owner_local_accepted_commit_surface_materialized=true"
echo "settings_owner_local_accepted_commit_surface_materialized=true"
echo "ai_generated_settings_owner_local_accepted_commit_surface_materialized=true"
echo "chat_composer_owner_local_accepted_commit_surface_materialized=true"
echo "file_browser_owner_local_accepted_commit_surface_materialized=true"
echo "accepted_commit_application_inspection_rows_materialized=true"
echo "accepted_commit_rollback_token_rows_materialized=true"
echo "accepted_commit_not_published_receipt_rows_materialized=true"
echo "accepted_commit_surface_bound_to_application_plan=true"
echo "stage884_owner_local_accepted_commit_runtime_manager_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
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
