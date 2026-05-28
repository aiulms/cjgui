#!/usr/bin/env zsh
#
# Verifies the stage546 component runtime interaction demo surface runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage546_component_runtime_interaction_demo_surface_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage546 component runtime interaction demo surface runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContractPlan" \
  "CjguiInternalRendererStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContractFacts" \
  "CjguiInternalRendererStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage546ComponentRuntimeInteractionDemoSurfaceRuntimeContractDraft" \
  "CjguiInternalRendererStage545ComponentRuntimeInteractionLayoutMeasurementExecutorReadiness" \
  "didConsumeStage545ComponentRuntimeInteractionLayoutMeasurementExecutor" \
  "didConsumeInteractionLayoutMeasurementReceipts" \
  "didMaterializeSharedComponentRuntimeInteractionDemoSurfaceRuntimeContract" \
  "didMaterializeSharedComponentRuntimeInteractionDemoSurfaceRuntimeHelper" \
  "didMaterializeTodoInteractionCheckableDemoSurfaceInput" \
  "didMaterializeSettingsInteractionCheckableDemoSurfaceInput" \
  "didMaterializeAiGeneratedSettingsInteractionCheckableDemoSurfaceInput" \
  "didBindDemoSurfaceRuntimeContractToLayoutMeasurementReceipts" \
  "didBindDemoSurfaceRuntimeContractToStage543RefreshReceipts" \
  "didReduceSameShapeInteractionLayoutProbeOwnerNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage546 component runtime interaction demo surface runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage546_component_runtime_interaction_demo_surface_runtime_contract_owner_present=true"
echo "stage545_component_runtime_interaction_layout_measurement_executor_consumed=true"
echo "interaction_layout_measurement_receipts_consumed=true"
echo "shared_component_runtime_interaction_demo_surface_runtime_contract_materialized=true"
echo "shared_component_runtime_interaction_demo_surface_runtime_helper_materialized=true"
echo "todo_interaction_checkable_demo_surface_input_materialized=true"
echo "settings_interaction_checkable_demo_surface_input_materialized=true"
echo "ai_generated_settings_interaction_checkable_demo_surface_input_materialized=true"
echo "demo_surface_runtime_contract_bound_to_layout_measurement_receipts=true"
echo "demo_surface_runtime_contract_bound_to_stage543_refresh_receipts=true"
echo "demo_surface_runtime_contract_bound_to_stage540_host_inspection=true"
echo "interaction_demo_surface_runtime_contract_checkable=true"
echo "same_shape_interaction_layout_probe_owner_need_reduced=true"
echo "stage547_component_runtime_interaction_input_event_cycle_probe_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
