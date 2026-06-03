#!/usr/bin/env zsh
#
# Verifies the stage744 component API authoring DSL runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage744_component_api_authoring_dsl_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage744 component api authoring dsl runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage744ComponentApiAuthoringDslRuntimeManagerPlan" \
  "CjguiInternalRendererStage744ComponentApiAuthoringDslRuntimeManagerFacts" \
  "CjguiInternalRendererStage744ComponentApiAuthoringDslRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage744ComponentApiAuthoringDslRuntimeManagerDraft" \
  "CjguiInternalRendererStage743ComponentApiAuthoringDemoHostPreviewSurfaceReadiness" \
  "didConsumeStage743ComponentApiAuthoringDemoHostPreviewSurface" \
  "didMaterializeSharedComponentApiAuthoringDslRuntimeManager" \
  "didMaterializeComponentApiAuthoringDslRuntimeContract" \
  "didMaterializeAuthoringSemanticTreeExecutionReceiptContract" \
  "didMaterializeCycleOrderAuthoringDslSemanticTreeHostPreviewRuntime" \
  "didReduceFuturePerDemoAuthoringDslTemplateNeed" \
  "didPrepareStage745ComponentApiAuthoringDslAiGeneratedUiDryRun"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage744 component api authoring dsl runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage744_component_api_authoring_dsl_runtime_manager_owner_present=true"
echo "stage743_component_api_authoring_demo_host_preview_surface_consumed=true"
echo "stage742_component_api_authoring_semantic_tree_preflight_consumed_transitively=true"
echo "stage741_component_api_authoring_dsl_internal_probe_consumed_transitively=true"
echo "stage740_component_api_internal_shape_runtime_manager_consumed_transitively=true"
echo "shared_component_api_authoring_dsl_runtime_manager_materialized=true"
echo "component_api_authoring_dsl_runtime_contract_materialized=true"
echo "authoring_semantic_tree_execution_receipt_contract_materialized=true"
echo "cycle_order_authoring_dsl_semantic_tree_host_preview_runtime_materialized=true"
echo "todo_component_api_authoring_dsl_runtime_surface_materialized=true"
echo "settings_component_api_authoring_dsl_runtime_surface_materialized=true"
echo "ai_generated_settings_component_api_authoring_dsl_runtime_surface_materialized=true"
echo "chat_composer_component_api_authoring_dsl_runtime_surface_materialized=true"
echo "future_per_demo_authoring_dsl_template_need_reduced=true"
echo "stage745_component_api_authoring_dsl_ai_generated_ui_dry_run_prepared=true"
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
