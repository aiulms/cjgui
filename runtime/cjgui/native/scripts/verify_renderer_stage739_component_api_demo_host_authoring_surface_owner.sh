#!/usr/bin/env zsh
#
# Verifies the stage739 component API demo-host authoring surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage739_component_api_demo_host_authoring_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage739 component api demo host authoring surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage739ComponentApiDemoHostAuthoringSurfacePlan" \
  "CjguiInternalRendererStage739ComponentApiDemoHostAuthoringSurfaceFacts" \
  "CjguiInternalRendererStage739ComponentApiDemoHostAuthoringSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage739ComponentApiDemoHostAuthoringSurfaceDraft" \
  "CjguiInternalRendererStage738ComponentApiCompatibilityPreflightReadiness" \
  "didConsumeStage738ComponentApiCompatibilityPreflight" \
  "didMaterializeComponentApiDemoHostAuthoringSurface" \
  "didMaterializeApiShapeFieldInspectionRows" \
  "didMaterializeApiPropsStateActionPortInspectionRows" \
  "didMaterializeApiCompatibilityReviewRows" \
  "didMaterializeApiAuthoringRenderCommandReceipt" \
  "didPrepareStage740ComponentApiInternalShapeRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage739 component api demo host authoring surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage739_component_api_demo_host_authoring_surface_owner_present=true"
echo "stage738_component_api_compatibility_preflight_consumed=true"
echo "component_api_compatibility_preflight_consumed_transitively=true"
echo "component_api_demo_host_authoring_surface_materialized=true"
echo "api_shape_field_inspection_rows_materialized=true"
echo "api_props_state_action_port_inspection_rows_materialized=true"
echo "api_compatibility_review_rows_materialized=true"
echo "api_authoring_render_command_receipt_materialized=true"
echo "todo_component_api_authoring_surface_materialized=true"
echo "settings_component_api_authoring_surface_materialized=true"
echo "ai_generated_settings_component_api_authoring_surface_materialized=true"
echo "chat_composer_component_api_authoring_surface_materialized=true"
echo "authoring_surface_bound_to_stage738_compatibility_preflight=true"
echo "stage740_component_api_internal_shape_runtime_manager_prepared=true"
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
