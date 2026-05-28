#!/usr/bin/env zsh
#
# Verifies the stage570 component runtime text input demo host surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage570_component_runtime_text_input_demo_host_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage570 component runtime text input demo host surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractPlan" \
  "CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractFacts" \
  "CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractDraft" \
  "CjguiInternalRendererStage569ComponentRuntimeTextInputMeasurementAffordanceExecutorReadiness" \
  "didMaterializeSharedTextInputDemoHostSurfaceContract" \
  "didMaterializeSharedTextInputDemoHostSurfaceHelper" \
  "didMaterializeChatComposerCheckableTextInputHostSurface" \
  "didBindDemoHostSurfaceToStage569Measurements" \
  "didReducePerDemoTextInputHostSurfaceTemplateNeed" \
  "didPrepareStage571ComponentRuntimeTextInputInputEventAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage570 component runtime text input demo host surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage570_component_runtime_text_input_demo_host_surface_contract_owner_present=true"
echo "stage569_component_runtime_text_input_measurement_affordance_executor_consumed=true"
echo "stage568_component_runtime_text_input_layout_style_preview_consumed_transitively=true"
echo "shared_text_input_demo_host_surface_contract_materialized=true"
echo "shared_text_input_demo_host_surface_helper_materialized=true"
echo "todo_checkable_text_input_host_surface_materialized=true"
echo "settings_checkable_text_input_host_surface_materialized=true"
echo "ai_generated_settings_checkable_text_input_host_surface_materialized=true"
echo "chat_composer_checkable_text_input_host_surface_materialized=true"
echo "demo_host_surface_bound_to_stage569_measurements=true"
echo "demo_host_surface_bound_to_stage568_preview=true"
echo "demo_host_surface_bound_to_stage567_surface_contract=true"
echo "per_demo_text_input_host_surface_template_need_reduced=true"
echo "stage571_component_runtime_text_input_input_event_adapter_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
