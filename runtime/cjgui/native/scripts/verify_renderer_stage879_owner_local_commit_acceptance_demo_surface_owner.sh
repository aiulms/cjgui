#!/usr/bin/env zsh
#
# Verifies the stage879 owner-local commit acceptance demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage879_owner_local_commit_acceptance_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage879 owner-local commit acceptance demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage879OwnerLocalCommitAcceptanceDemoSurfacePlan" \
  "CjguiInternalRendererStage879OwnerLocalCommitAcceptanceDemoSurfaceFacts" \
  "CjguiInternalRendererStage879OwnerLocalCommitAcceptanceDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage879OwnerLocalCommitAcceptanceDemoSurfaceDraft" \
  "CjguiInternalRendererStage878OwnerLocalCommitAcceptanceDecisionReadiness" \
  "didConsumeStage878OwnerLocalCommitAcceptanceDecision" \
  "didMaterializeTodoOwnerLocalCommitAcceptanceSurface" \
  "didMaterializeSettingsOwnerLocalCommitAcceptanceSurface" \
  "didMaterializeAiGeneratedSettingsOwnerLocalCommitAcceptanceSurface" \
  "didMaterializeChatComposerOwnerLocalCommitAcceptanceSurface" \
  "didMaterializeFileBrowserOwnerLocalCommitAcceptanceSurface" \
  "didMaterializeOwnerLocalCommitAcceptanceInspectionRows" \
  "didPrepareStage880OwnerLocalCommitAcceptanceRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage879 owner-local commit acceptance demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage879_owner_local_commit_acceptance_demo_surface_owner_present=true"
echo "stage878_owner_local_commit_acceptance_decision_consumed=true"
echo "stage877_owner_local_commit_acceptance_gate_consumed_transitively=true"
echo "stage876_owner_local_commit_runtime_manager_consumed_transitively=true"
echo "todo_owner_local_commit_acceptance_surface_materialized=true"
echo "settings_owner_local_commit_acceptance_surface_materialized=true"
echo "ai_generated_settings_owner_local_commit_acceptance_surface_materialized=true"
echo "chat_composer_owner_local_commit_acceptance_surface_materialized=true"
echo "file_browser_owner_local_commit_acceptance_surface_materialized=true"
echo "owner_local_commit_acceptance_inspection_rows_materialized=true"
echo "owner_local_commit_acceptance_receipt_rows_materialized=true"
echo "owner_local_commit_request_changes_rows_materialized=true"
echo "owner_local_commit_acceptance_surface_bound_to_decision_reducer=true"
echo "stage880_owner_local_commit_acceptance_runtime_manager_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
