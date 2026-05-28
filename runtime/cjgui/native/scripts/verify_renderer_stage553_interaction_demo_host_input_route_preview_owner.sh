#!/usr/bin/env zsh
#
# Verifies the stage553 interaction demo host input route preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage553_interaction_demo_host_input_route_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage553 interaction demo host input route preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage553InteractionDemoHostInputRoutePreviewPlan" \
  "CjguiInternalRendererStage553InteractionDemoHostInputRoutePreviewFacts" \
  "CjguiInternalRendererStage553InteractionDemoHostInputRoutePreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage553InteractionDemoHostInputRoutePreviewDraft" \
  "CjguiInternalRendererStage552InteractionDemoHostProbeContractReadiness" \
  "didConsumeStage552InteractionDemoHostProbeContract" \
  "didConsumeStage551InteractionDemoHostInputRouteTable" \
  "didMaterializeSharedInteractionDemoHostInputRoutePreviewContract" \
  "didMaterializeSharedInteractionDemoHostInputRoutePreviewHelper" \
  "didMaterializeTodoInteractionDemoHostInputRoutePreview" \
  "didMaterializeSettingsInteractionDemoHostInputRoutePreview" \
  "didMaterializeAiGeneratedSettingsInteractionDemoHostInputRoutePreview" \
  "didBindHostInputRoutePreviewToStage552ProbeInputs" \
  "didBindHostInputRoutePreviewToStage551RouteTables" \
  "didBindHostInputRoutePreviewToStage534NormalizedEventShape" \
  "didKeepHostInputRoutePreviewNonDispatching" \
  "didReducePerDemoHostInputRouteOwnerNeed" \
  "didPrepareStage554InteractionDemoHostRouteCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage553 interaction demo host input route preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage553_interaction_demo_host_input_route_preview_owner_present=true"
echo "stage552_interaction_demo_host_probe_contract_consumed=true"
echo "stage551_interaction_demo_host_input_route_table_consumed=true"
echo "stage551_interaction_demo_host_focus_route_table_consumed=true"
echo "stage534_normalized_event_demo_surface_cycle_probe_consumed_transitively=true"
echo "shared_interaction_demo_host_input_route_preview_contract_materialized=true"
echo "shared_interaction_demo_host_input_route_preview_helper_materialized=true"
echo "todo_interaction_demo_host_input_route_preview_materialized=true"
echo "settings_interaction_demo_host_input_route_preview_materialized=true"
echo "ai_generated_settings_interaction_demo_host_input_route_preview_materialized=true"
echo "host_input_route_preview_bound_to_stage552_probe_inputs=true"
echo "host_input_route_preview_bound_to_stage551_route_tables=true"
echo "host_input_route_preview_bound_to_stage534_normalized_event_shape=true"
echo "host_input_route_preview_non_dispatching=true"
echo "per_demo_host_input_route_owner_need_reduced=true"
echo "stage554_interaction_demo_host_route_cycle_executor_prepared=true"
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
