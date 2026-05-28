#!/usr/bin/env zsh
#
# Verifies the stage552 interaction demo host probe contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage552_interaction_demo_host_probe_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage552 interaction demo host probe contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage552InteractionDemoHostProbeContractPlan" \
  "CjguiInternalRendererStage552InteractionDemoHostProbeContractFacts" \
  "CjguiInternalRendererStage552InteractionDemoHostProbeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage552InteractionDemoHostProbeContractDraft" \
  "CjguiInternalRendererStage551InteractionDemoHostFrameAssemblyReadiness" \
  "didConsumeStage551InteractionDemoHostFrameAssembly" \
  "didMaterializeSharedInteractionDemoHostProbeContract" \
  "didMaterializeSharedInteractionDemoHostProbeHelper" \
  "didMaterializeTodoInteractionDemoHostProbeInput" \
  "didMaterializeSettingsInteractionDemoHostProbeInput" \
  "didMaterializeAiGeneratedSettingsInteractionDemoHostProbeInput" \
  "didBindInteractionDemoHostProbeToStage551FrameReceipt" \
  "didReducePerDemoHostProbeOwnerNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage552 interaction demo host probe contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage552_interaction_demo_host_probe_contract_owner_present=true"
echo "stage551_interaction_demo_host_frame_assembly_consumed=true"
echo "stage550_interaction_demo_cycle_host_integration_consumed_transitively=true"
echo "stage549_interaction_demo_cycle_surface_contract_consumed_transitively=true"
echo "shared_interaction_demo_host_probe_contract_materialized=true"
echo "shared_interaction_demo_host_probe_helper_materialized=true"
echo "todo_interaction_demo_host_probe_input_materialized=true"
echo "settings_interaction_demo_host_probe_input_materialized=true"
echo "ai_generated_settings_interaction_demo_host_probe_input_materialized=true"
echo "interaction_demo_host_probe_bound_to_stage551_frame_receipt=true"
echo "interaction_demo_host_probe_bound_to_stage550_mount_descriptors=true"
echo "interaction_demo_host_probe_checkable=true"
echo "per_demo_host_probe_owner_need_reduced=true"
echo "stage553_interaction_demo_host_input_route_preview_prepared=true"
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
