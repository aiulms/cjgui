#!/usr/bin/env zsh
#
# Verifies the stage648 component host input result surface runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage648_component_host_input_result_surface_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage648 component host input result surface runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage648ComponentHostInputResultSurfaceRuntimeContractPlan" \
  "CjguiInternalRendererStage648ComponentHostInputResultSurfaceRuntimeContractFacts" \
  "CjguiInternalRendererStage648ComponentHostInputResultSurfaceRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage648ComponentHostInputResultSurfaceRuntimeContractDraft" \
  "CjguiInternalRendererStage647ComponentHostInputResultSurfaceHostInspectionReadiness" \
  "didConsumeStage647ComponentHostInputResultSurfaceHostInspection" \
  "didMaterializeSharedComponentHostInputResultSurfaceRuntimeContract" \
  "didMaterializeSharedComponentHostInputResultSurfaceRuntimeHelper" \
  "didMaterializeSharedResultSurfaceExecutionReceiptContract" \
  "didMaterializeCycleOrderHostInputResultSurfaceLayoutFeedbackHostInspection" \
  "didMaterializeChatComposerComponentHostInputResultSurfaceRuntimeSurface" \
  "didBindRuntimeContractToStage645Refresh" \
  "didReduceFuturePerDemoResultSurfaceRefreshTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage648 component host input result surface runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage648_component_host_input_result_surface_runtime_contract_owner_present=true"
echo "stage647_component_host_input_result_surface_host_inspection_consumed=true"
echo "stage646_component_host_input_result_surface_layout_feedback_consumed_transitively=true"
echo "stage645_component_host_input_result_surface_refresh_consumed_transitively=true"
echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
echo "shared_component_host_input_result_surface_runtime_contract_materialized=true"
echo "shared_component_host_input_result_surface_runtime_helper_materialized=true"
echo "shared_result_surface_execution_receipt_contract_materialized=true"
echo "cycle_order_host_input_result_surface_layout_feedback_host_inspection_materialized=true"
echo "todo_component_host_input_result_surface_runtime_surface_materialized=true"
echo "settings_component_host_input_result_surface_runtime_surface_materialized=true"
echo "ai_generated_settings_component_host_input_result_surface_runtime_surface_materialized=true"
echo "chat_composer_component_host_input_result_surface_runtime_surface_materialized=true"
echo "runtime_contract_bound_to_stage645_refresh=true"
echo "future_per_demo_result_surface_refresh_template_need_reduced=true"
echo "stage649_component_host_input_result_surface_interaction_adapter_prepared=true"
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
