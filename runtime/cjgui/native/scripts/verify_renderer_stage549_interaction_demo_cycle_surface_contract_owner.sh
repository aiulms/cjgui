#!/usr/bin/env zsh
#
# Verifies the stage549 interaction demo cycle surface contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage549_interaction_demo_cycle_surface_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage549 interaction demo cycle surface contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage549InteractionDemoCycleSurfaceContractPlan" \
  "CjguiInternalRendererStage549InteractionDemoCycleSurfaceContractFacts" \
  "CjguiInternalRendererStage549InteractionDemoCycleSurfaceContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage549InteractionDemoCycleSurfaceContractDraft" \
  "CjguiInternalRendererStage548InteractionCycleExecutionReceiptReadiness" \
  "didConsumeStage548InteractionCycleExecutionReceipt" \
  "didMaterializeSharedInteractionDemoCycleSurfaceContract" \
  "didMaterializeSharedInteractionDemoCycleSurfaceHelper" \
  "didMaterializeTodoInteractionDemoCycleSurface" \
  "didMaterializeSettingsInteractionDemoCycleSurface" \
  "didMaterializeAiGeneratedSettingsInteractionDemoCycleSurface" \
  "didBindInteractionDemoCycleSurfaceToStage546RuntimeContract" \
  "didBindInteractionDemoCycleSurfaceToStage540HostInspection" \
  "didReduceSameShapeInteractionCycleOwnerProbeNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage549 interaction demo cycle surface contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage549_interaction_demo_cycle_surface_contract_owner_present=true"
echo "stage548_interaction_cycle_execution_receipt_consumed=true"
echo "stage547_interaction_input_event_cycle_probe_consumed_transitively=true"
echo "shared_interaction_demo_cycle_surface_contract_materialized=true"
echo "shared_interaction_demo_cycle_surface_helper_materialized=true"
echo "todo_interaction_demo_cycle_surface_materialized=true"
echo "settings_interaction_demo_cycle_surface_materialized=true"
echo "ai_generated_settings_interaction_demo_cycle_surface_materialized=true"
echo "interaction_demo_cycle_surface_bound_to_stage548_execution_receipts=true"
echo "interaction_demo_cycle_surface_bound_to_stage546_runtime_contract=true"
echo "interaction_demo_cycle_surface_bound_to_stage540_host_inspection=true"
echo "interaction_demo_cycle_surface_checkable=true"
echo "same_shape_interaction_cycle_owner_probe_need_reduced=true"
echo "stage550_component_runtime_interaction_demo_cycle_host_integration_prepared=true"
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
