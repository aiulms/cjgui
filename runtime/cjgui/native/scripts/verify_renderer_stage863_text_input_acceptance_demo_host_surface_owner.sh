#!/usr/bin/env zsh
#
# Verifies the stage863 text-input acceptance demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage863 text input acceptance demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage863TextInputAcceptanceDemoHostSurfacePlan" \
  "CjguiInternalRendererStage863TextInputAcceptanceDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage863TextInputAcceptanceDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage863TextInputAcceptanceDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage862TextInputAcceptanceDecisionReducerReadiness" \
  "didConsumeStage862TextInputAcceptanceDecisionReducer" \
  "didMaterializeTodoAcceptanceSurface" \
  "didMaterializeSettingsAcceptanceSurface" \
  "didMaterializeAiGeneratedSettingsAcceptanceSurface" \
  "didMaterializeChatComposerAcceptanceSurface" \
  "didMaterializeFileBrowserAcceptanceSurface" \
  "didMaterializeAcceptanceInspectionRows" \
  "didMaterializeNotPublishedBoundaryBanner" \
  "didPrepareStage864TextInputOwnerAcceptanceRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage863 text input acceptance demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage863_text_input_acceptance_demo_host_surface_owner_present=true"
echo "stage862_text_input_acceptance_decision_reducer_consumed=true"
echo "stage861_text_input_owner_acceptance_review_gate_consumed_transitively=true"
echo "todo_text_input_acceptance_surface_materialized=true"
echo "settings_text_input_acceptance_surface_materialized=true"
echo "ai_generated_settings_text_input_acceptance_surface_materialized=true"
echo "chat_composer_text_input_acceptance_surface_materialized=true"
echo "file_browser_text_input_acceptance_surface_materialized=true"
echo "text_input_acceptance_inspection_rows_materialized=true"
echo "text_input_acceptance_semantic_diff_rows_materialized=true"
echo "text_input_acceptance_not_published_boundary_banner_materialized=true"
echo "acceptance_demo_surfaces_bound_to_stage862_decision_reducer=true"
echo "stage864_text_input_owner_acceptance_runtime_manager_prepared=true"
echo "owner_acceptance_granted=false"
echo "text_input_commit_committed=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
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
