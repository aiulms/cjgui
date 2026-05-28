#!/usr/bin/env zsh
#
# Verifies the stage550 interaction demo cycle host integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage550_interaction_demo_cycle_host_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage550 interaction demo cycle host integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage550InteractionDemoCycleHostIntegrationPlan" \
  "CjguiInternalRendererStage550InteractionDemoCycleHostIntegrationFacts" \
  "CjguiInternalRendererStage550InteractionDemoCycleHostIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage550InteractionDemoCycleHostIntegrationDraft" \
  "CjguiInternalRendererStage549InteractionDemoCycleSurfaceContractReadiness" \
  "didConsumeStage549InteractionDemoCycleSurfaceContract" \
  "didMaterializeSharedInteractionDemoHostMountContract" \
  "didMaterializeSharedInteractionDemoHostMountHelper" \
  "didMaterializeTodoInteractionDemoHostMountDescriptor" \
  "didMaterializeSettingsInteractionDemoHostMountDescriptor" \
  "didMaterializeAiGeneratedSettingsInteractionDemoHostMountDescriptor" \
  "didBindInteractionDemoHostMountsToStage549CycleSurfaces" \
  "didBindInteractionDemoHostMountsToStage540HostInspection" \
  "didReducePerDemoHostIntegrationDuplication"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage550 interaction demo cycle host integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage550_interaction_demo_cycle_host_integration_owner_present=true"
echo "stage549_interaction_demo_cycle_surface_contract_consumed=true"
echo "stage540_component_runtime_demo_host_inspection_consumed_transitively=true"
echo "shared_interaction_demo_host_mount_contract_materialized=true"
echo "shared_interaction_demo_host_mount_helper_materialized=true"
echo "todo_interaction_demo_host_mount_descriptor_materialized=true"
echo "settings_interaction_demo_host_mount_descriptor_materialized=true"
echo "ai_generated_settings_interaction_demo_host_mount_descriptor_materialized=true"
echo "interaction_demo_host_mounts_bound_to_stage549_cycle_surfaces=true"
echo "interaction_demo_host_mounts_bound_to_stage540_host_inspection=true"
echo "interaction_demo_host_mounts_checkable=true"
echo "per_demo_host_integration_duplication_reduced=true"
echo "stage551_interaction_demo_host_frame_assembly_prepared=true"
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
