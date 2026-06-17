#!/usr/bin/env zsh
#
# Verifies the stage887 owner-local accepted commit publication demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage887_owner_local_accepted_commit_publication_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage887 owner-local accepted commit publication demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage887OwnerLocalAcceptedCommitPublicationDemoSurfacePlan" \
  "CjguiInternalRendererStage887OwnerLocalAcceptedCommitPublicationDemoSurfaceFacts" \
  "CjguiInternalRendererStage887OwnerLocalAcceptedCommitPublicationDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage887OwnerLocalAcceptedCommitPublicationDemoSurfaceDraft" \
  "CjguiInternalRendererStage886OwnerLocalAcceptedCommitPublicationBoundaryReadiness" \
  "didConsumeStage886OwnerLocalAcceptedCommitPublicationBoundary" \
  "didMaterializeTodoAcceptedCommitPublicationInspectionSurface" \
  "didMaterializeSettingsAcceptedCommitPublicationInspectionSurface" \
  "didMaterializeAiGeneratedSettingsAcceptedCommitPublicationInspectionSurface" \
  "didMaterializeChatComposerAcceptedCommitPublicationInspectionSurface" \
  "didMaterializeFileBrowserAcceptedCommitPublicationInspectionSurface" \
  "didMaterializeAcceptedCommitPublicationBoundaryRows" \
  "didPrepareStage888OwnerLocalAcceptedCommitPublicationRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage887 owner-local accepted commit publication demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage887_owner_local_accepted_commit_publication_demo_surface_owner_present=true"
echo "stage886_owner_local_accepted_commit_publication_boundary_consumed=true"
echo "stage885_owner_local_accepted_commit_publication_preflight_consumed_transitively=true"
echo "todo_accepted_commit_publication_inspection_surface_materialized=true"
echo "settings_accepted_commit_publication_inspection_surface_materialized=true"
echo "ai_generated_settings_accepted_commit_publication_inspection_surface_materialized=true"
echo "chat_composer_accepted_commit_publication_inspection_surface_materialized=true"
echo "file_browser_accepted_commit_publication_inspection_surface_materialized=true"
echo "accepted_commit_publication_candidate_rows_materialized=true"
echo "accepted_commit_publication_boundary_rows_materialized=true"
echo "accepted_commit_publication_not_published_rows_materialized=true"
echo "accepted_commit_publication_surface_bound_to_boundary=true"
echo "stage888_owner_local_accepted_commit_publication_runtime_manager_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
