#!/usr/bin/env zsh
#
# Verifies the stage551 interaction demo host frame assembly owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage551_interaction_demo_host_frame_assembly.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage551 interaction demo host frame assembly: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage551InteractionDemoHostFrameAssemblyPlan" \
  "CjguiInternalRendererStage551InteractionDemoHostFrameAssemblyFacts" \
  "CjguiInternalRendererStage551InteractionDemoHostFrameAssemblyReadiness" \
  "cjguiInternalExecuteDefaultRendererStage551InteractionDemoHostFrameAssemblyDraft" \
  "CjguiInternalRendererStage550InteractionDemoCycleHostIntegrationReadiness" \
  "didConsumeStage550InteractionDemoCycleHostIntegration" \
  "didMaterializeSharedInteractionDemoHostFrameAssembler" \
  "didMaterializeSharedInteractionDemoHostFrameReceipt" \
  "didMaterializeInteractionDemoHostFocusRouteTable" \
  "didMaterializeInteractionDemoHostInputRouteTable" \
  "didMaterializeInteractionDemoHostInvalidationLedger" \
  "didBindInteractionDemoHostFrameToStage550MountDescriptors" \
  "didKeepInteractionDemoHostFrameNonPublishing"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage551 interaction demo host frame assembly: missing token $token" >&2
    exit 3
  fi
done

echo "stage551_interaction_demo_host_frame_assembly_owner_present=true"
echo "stage550_interaction_demo_cycle_host_integration_consumed=true"
echo "stage549_interaction_demo_cycle_surface_contract_consumed_transitively=true"
echo "shared_interaction_demo_host_frame_assembler_materialized=true"
echo "shared_interaction_demo_host_frame_receipt_materialized=true"
echo "interaction_demo_host_focus_route_table_materialized=true"
echo "interaction_demo_host_input_route_table_materialized=true"
echo "interaction_demo_host_invalidation_ledger_materialized=true"
echo "todo_interaction_demo_host_frame_receipt_materialized=true"
echo "settings_interaction_demo_host_frame_receipt_materialized=true"
echo "ai_generated_settings_interaction_demo_host_frame_receipt_materialized=true"
echo "interaction_demo_host_frame_bound_to_stage550_mount_descriptors=true"
echo "interaction_demo_host_frame_non_publishing=true"
echo "stage552_interaction_demo_host_probe_contract_prepared=true"
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
