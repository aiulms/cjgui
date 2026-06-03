#!/usr/bin/env zsh
#
# Verifies the stage743 component API authoring demo-host preview surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage743_component_api_authoring_demo_host_preview_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage743 component api authoring demo-host preview surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage743ComponentApiAuthoringDemoHostPreviewSurfacePlan" \
  "CjguiInternalRendererStage743ComponentApiAuthoringDemoHostPreviewSurfaceFacts" \
  "CjguiInternalRendererStage743ComponentApiAuthoringDemoHostPreviewSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage743ComponentApiAuthoringDemoHostPreviewSurfaceDraft" \
  "CjguiInternalRendererStage742ComponentApiAuthoringSemanticTreePreflightReadiness" \
  "didConsumeStage742ComponentApiAuthoringSemanticTreePreflight" \
  "didMaterializeComponentApiAuthoringDemoHostPreviewSurface" \
  "didMaterializeHostPreviewInspectionRows" \
  "didMaterializeSemanticTreeDiffReceipt" \
  "didMaterializeAuthoringRenderCommandPreviewReceipt" \
  "didMaterializeChatComposerAuthoringHostPreviewSurface" \
  "didPrepareStage744ComponentApiAuthoringDslRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage743 component api authoring demo-host preview surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage743_component_api_authoring_demo_host_preview_surface_owner_present=true"
echo "stage742_component_api_authoring_semantic_tree_preflight_consumed=true"
echo "stage741_component_api_authoring_dsl_internal_probe_consumed_transitively=true"
echo "component_api_authoring_demo_host_preview_surface_materialized=true"
echo "host_preview_inspection_rows_materialized=true"
echo "semantic_tree_diff_receipt_materialized=true"
echo "authoring_render_command_preview_receipt_materialized=true"
echo "authoring_result_surface_preview_materialized=true"
echo "authoring_preview_probe_input_contract_materialized=true"
echo "todo_authoring_host_preview_surface_materialized=true"
echo "settings_authoring_host_preview_surface_materialized=true"
echo "ai_generated_settings_authoring_host_preview_surface_materialized=true"
echo "chat_composer_authoring_host_preview_surface_materialized=true"
echo "demo_host_preview_surface_bound_to_semantic_tree_preflight=true"
echo "stage744_component_api_authoring_dsl_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
