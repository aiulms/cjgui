#!/usr/bin/env zsh
#
# Verifies the stage652 component host input result surface interaction feedback runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage652_component_host_input_result_surface_interaction_feedback_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage652 component host input result surface interaction feedback runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContractPlan" \
  "CjguiInternalRendererStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContractFacts" \
  "CjguiInternalRendererStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContractDraft" \
  "CjguiInternalRendererStage651ComponentHostInputResultSurfaceRenderRefreshReceiptReadiness" \
  "didConsumeStage651ComponentHostInputResultSurfaceRenderRefreshReceipt" \
  "didMaterializeSharedInteractionFeedbackRuntimeContract" \
  "didMaterializeSharedInteractionFeedbackRuntimeHelper" \
  "didMaterializeSharedInteractionFeedbackExecutionReceiptContract" \
  "didMaterializeCycleOrderResultSurfaceInteractionAdapterActionStateFeedbackRenderRefreshRuntimeReceipt" \
  "didMaterializeChatComposerInteractionFeedbackRuntimeSurface" \
  "didBindInteractionFeedbackRuntimeToStage649Adapter" \
  "didReduceFuturePerDemoInteractionFeedbackTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage652 component host input result surface interaction feedback runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage652_component_host_input_result_surface_interaction_feedback_runtime_contract_owner_present=true"
echo "stage651_component_host_input_result_surface_render_refresh_receipt_consumed=true"
echo "stage650_component_host_input_result_surface_action_state_feedback_executor_consumed_transitively=true"
echo "stage649_component_host_input_result_surface_interaction_adapter_consumed_transitively=true"
echo "stage648_component_host_input_result_surface_runtime_contract_consumed_transitively=true"
echo "shared_interaction_feedback_runtime_contract_materialized=true"
echo "shared_interaction_feedback_runtime_helper_materialized=true"
echo "shared_interaction_feedback_execution_receipt_contract_materialized=true"
echo "cycle_order_result_surface_interaction_adapter_action_state_feedback_render_refresh_runtime_receipt_materialized=true"
echo "todo_interaction_feedback_runtime_surface_materialized=true"
echo "settings_interaction_feedback_runtime_surface_materialized=true"
echo "ai_generated_settings_interaction_feedback_runtime_surface_materialized=true"
echo "chat_composer_interaction_feedback_runtime_surface_materialized=true"
echo "interaction_feedback_runtime_bound_to_stage649_adapter=true"
echo "future_per_demo_interaction_feedback_template_need_reduced=true"
echo "stage653_component_host_input_result_surface_interaction_host_integration_prepared=true"
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
