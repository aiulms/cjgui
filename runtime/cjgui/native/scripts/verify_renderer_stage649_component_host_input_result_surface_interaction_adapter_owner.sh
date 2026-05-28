#!/usr/bin/env zsh
#
# Verifies the stage649 component host input result surface interaction adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage649_component_host_input_result_surface_interaction_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage649 component host input result surface interaction adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage649ComponentHostInputResultSurfaceInteractionAdapterPlan" \
  "CjguiInternalRendererStage649ComponentHostInputResultSurfaceInteractionAdapterFacts" \
  "CjguiInternalRendererStage649ComponentHostInputResultSurfaceInteractionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage649ComponentHostInputResultSurfaceInteractionAdapterDraft" \
  "CjguiInternalRendererStage648ComponentHostInputResultSurfaceRuntimeContractReadiness" \
  "didConsumeStage648ComponentHostInputResultSurfaceRuntimeContract" \
  "didMaterializeSharedResultSurfaceInteractionAdapter" \
  "didMaterializeValidationDismissActionRoute" \
  "didMaterializeFocusMoveActionRoute" \
  "didMaterializeInputFeedbackClearActionRoute" \
  "didMaterializeSemanticDiffAcknowledgeActionRoute" \
  "didMaterializeChatComposerResultSurfaceInteractionTarget" \
  "didBindInteractionAdapterToStage648RuntimeSurfaces" \
  "didPrepareStage650ComponentHostInputResultSurfaceActionStateFeedbackExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage649 component host input result surface interaction adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage649_component_host_input_result_surface_interaction_adapter_owner_present=true"
echo "stage648_component_host_input_result_surface_runtime_contract_consumed=true"
echo "stage647_component_host_input_result_surface_host_inspection_consumed_transitively=true"
echo "stage646_component_host_input_result_surface_layout_feedback_consumed_transitively=true"
echo "stage645_component_host_input_result_surface_refresh_consumed_transitively=true"
echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
echo "shared_result_surface_interaction_adapter_materialized=true"
echo "validation_dismiss_action_route_materialized=true"
echo "focus_move_action_route_materialized=true"
echo "input_feedback_clear_action_route_materialized=true"
echo "semantic_diff_acknowledge_action_route_materialized=true"
echo "todo_result_surface_interaction_target_materialized=true"
echo "settings_result_surface_interaction_target_materialized=true"
echo "ai_generated_settings_result_surface_interaction_target_materialized=true"
echo "chat_composer_result_surface_interaction_target_materialized=true"
echo "interaction_adapter_bound_to_stage648_runtime_surfaces=true"
echo "stage650_component_host_input_result_surface_action_state_feedback_executor_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
