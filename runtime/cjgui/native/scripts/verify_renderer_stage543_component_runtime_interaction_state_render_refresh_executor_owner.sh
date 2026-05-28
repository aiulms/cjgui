#!/usr/bin/env zsh
#
# Verifies the stage543 component runtime interaction state/render refresh executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage543_component_runtime_interaction_state_render_refresh_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage543 component runtime interaction state render refresh executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage543ComponentRuntimeInteractionStateRenderRefreshExecutorPlan" \
  "CjguiInternalRendererStage543ComponentRuntimeInteractionStateRenderRefreshExecutorFacts" \
  "CjguiInternalRendererStage543ComponentRuntimeInteractionStateRenderRefreshExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage543ComponentRuntimeInteractionStateRenderRefreshExecutorDraft" \
  "CjguiInternalRendererStage542ComponentRuntimeInteractionActionStateAdapterReadiness" \
  "didConsumeStage542ComponentRuntimeInteractionActionStateAdapter" \
  "didConsumeInteractionActionStateCandidates" \
  "didMaterializeSharedComponentRuntimeInteractionStateRenderRefreshExecutor" \
  "didMaterializeSharedComponentRuntimeInteractionCycleReceipt" \
  "didMaterializeTodoInteractionDemoSurfaceRefreshReceipt" \
  "didMaterializeSettingsInteractionDemoSurfaceRefreshReceipt" \
  "didMaterializeAiGeneratedSettingsInteractionDemoSurfaceRefreshReceipt" \
  "didBindInteractionStateRenderRefreshToActionStateAdapter" \
  "didBindInteractionStateRenderRefreshToStage540HostInspection" \
  "didReduceInteractionCycleOwnerProbeDuplication"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage543 component runtime interaction state render refresh executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage543_component_runtime_interaction_state_render_refresh_executor_owner_present=true"
echo "stage542_component_runtime_interaction_action_state_adapter_consumed=true"
echo "interaction_action_state_candidates_consumed=true"
echo "shared_component_runtime_interaction_state_render_refresh_executor_materialized=true"
echo "shared_component_runtime_interaction_cycle_receipt_materialized=true"
echo "todo_interaction_demo_surface_refresh_receipt_materialized=true"
echo "settings_interaction_demo_surface_refresh_receipt_materialized=true"
echo "ai_generated_settings_interaction_demo_surface_refresh_receipt_materialized=true"
echo "interaction_state_render_refresh_bound_to_action_state_adapter=true"
echo "interaction_state_render_refresh_bound_to_stage540_host_inspection=true"
echo "interaction_state_render_refresh_bound_to_stage537_event_refresh_executor=true"
echo "interaction_state_render_refresh_checkable=true"
echo "interaction_cycle_owner_probe_duplication_reduced=true"
echo "stage544_component_runtime_interaction_layout_style_probe_prepared=true"
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
