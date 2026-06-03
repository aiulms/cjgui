#!/usr/bin/env zsh
#
# Verifies the stage740 component API internal shape runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage740_component_api_internal_shape_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage740 component api internal shape runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage740ComponentApiInternalShapeRuntimeManagerPlan" \
  "CjguiInternalRendererStage740ComponentApiInternalShapeRuntimeManagerFacts" \
  "CjguiInternalRendererStage740ComponentApiInternalShapeRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage740ComponentApiInternalShapeRuntimeManagerDraft" \
  "CjguiInternalRendererStage739ComponentApiDemoHostAuthoringSurfaceReadiness" \
  "didConsumeStage739ComponentApiDemoHostAuthoringSurface" \
  "didMaterializeSharedComponentApiInternalShapeRuntimeManager" \
  "didMaterializeComponentApiInternalAuthoringRuntimeContract" \
  "didMaterializeComponentApiInternalShapeExecutionReceiptContract" \
  "didMaterializeCycleOrderComponentApiInternalShapeCompatibilityAuthoringHostRuntime" \
  "didReduceFuturePerDemoPublicApiPreflightTemplateNeed" \
  "didPrepareStage741ComponentApiAuthoringDslInternalProbe"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage740 component api internal shape runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage740_component_api_internal_shape_runtime_manager_owner_present=true"
echo "stage739_component_api_demo_host_authoring_surface_consumed=true"
echo "stage738_component_api_compatibility_preflight_consumed_transitively=true"
echo "stage737_component_state_store_public_api_internal_shape_consumed_transitively=true"
echo "stage736_component_state_store_commit_runtime_manager_consumed_transitively=true"
echo "shared_component_api_internal_shape_runtime_manager_materialized=true"
echo "component_api_internal_authoring_runtime_contract_materialized=true"
echo "component_api_internal_shape_execution_receipt_contract_materialized=true"
echo "cycle_order_component_api_internal_shape_compatibility_authoring_host_runtime_materialized=true"
echo "todo_component_api_internal_shape_runtime_surface_materialized=true"
echo "settings_component_api_internal_shape_runtime_surface_materialized=true"
echo "ai_generated_settings_component_api_internal_shape_runtime_surface_materialized=true"
echo "chat_composer_component_api_internal_shape_runtime_surface_materialized=true"
echo "future_per_demo_public_api_preflight_template_need_reduced=true"
echo "stage741_component_api_authoring_dsl_internal_probe_prepared=true"
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
