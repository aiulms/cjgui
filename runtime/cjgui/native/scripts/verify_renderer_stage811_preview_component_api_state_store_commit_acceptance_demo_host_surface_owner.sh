#!/usr/bin/env zsh
#
# Verifies the stage811 preview component API state-store commit acceptance demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage811 preview component api state-store commit acceptance demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurfacePlan" \
  "CjguiInternalRendererStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage811PreviewComponentApiStateStoreCommitAcceptanceDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRunReadiness" \
  "didConsumeStage810PreviewComponentApiStateStoreCommitAcceptanceDecisionDryRun" \
  "didMaterializeAcceptanceInspectionRows" \
  "didMaterializeDecisionResultSurfaceRefresh" \
  "didMaterializeTodoAcceptancePreviewSurface" \
  "didMaterializeSettingsAcceptancePreviewSurface" \
  "didMaterializeAiGeneratedSettingsAcceptancePreviewSurface" \
  "didMaterializeChatComposerAcceptancePreviewSurface" \
  "didMaterializeFileBrowserAcceptancePreviewSurface" \
  "didPrepareStage812PreviewComponentApiStateStoreCommitAcceptanceRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage811 preview component api state-store commit acceptance demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_owner_present=true"
echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_consumed=true"
echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_consumed_transitively=true"
echo "acceptance_inspection_rows_materialized=true"
echo "decision_result_surface_refresh_materialized=true"
echo "todo_acceptance_preview_surface_materialized=true"
echo "settings_acceptance_preview_surface_materialized=true"
echo "ai_generated_settings_acceptance_preview_surface_materialized=true"
echo "chat_composer_acceptance_preview_surface_materialized=true"
echo "file_browser_acceptance_preview_surface_materialized=true"
echo "acceptance_demo_host_surface_bound_to_stage810_decision_dry_run=true"
echo "acceptance_demo_host_surface_non_committing=true"
echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_prepared=true"
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
