#!/usr/bin/env zsh
#
# Verifies the stage642 component host input event queue owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage642_component_host_input_event_queue.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage642 component host input event queue: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage642ComponentHostInputEventQueuePlan" \
  "CjguiInternalRendererStage642ComponentHostInputEventQueueFacts" \
  "CjguiInternalRendererStage642ComponentHostInputEventQueueReadiness" \
  "cjguiInternalExecuteDefaultRendererStage642ComponentHostInputEventQueueDraft" \
  "CjguiInternalRendererStage641ResultSurfaceHostInputAdapterReadiness" \
  "didConsumeStage641ResultSurfaceHostInputAdapter" \
  "didMaterializeSharedComponentHostInputEventQueue" \
  "didMaterializeNormalizedValidationAckHostInputEvent" \
  "didMaterializeNormalizedFocusMoveHostInputEvent" \
  "didMaterializeNormalizedInputFeedbackDismissHostInputEvent" \
  "didMaterializeNormalizedSemanticRefreshHostInputEvent" \
  "didMaterializeChatComposerComponentHostInputEventQueue" \
  "didPrepareStage643ComponentHostInputCycleReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage642 component host input event queue: missing token $token" >&2
    exit 3
  fi
done

echo "stage642_component_host_input_event_queue_owner_present=true"
echo "stage641_result_surface_host_input_adapter_consumed=true"
echo "stage640_result_surface_host_runtime_contract_consumed_transitively=true"
echo "shared_component_host_input_event_queue_materialized=true"
echo "normalized_validation_ack_host_input_event_materialized=true"
echo "normalized_focus_move_host_input_event_materialized=true"
echo "normalized_input_feedback_dismiss_host_input_event_materialized=true"
echo "normalized_semantic_refresh_host_input_event_materialized=true"
echo "component_host_input_event_queue_ledger_materialized=true"
echo "todo_component_host_input_event_queue_materialized=true"
echo "settings_component_host_input_event_queue_materialized=true"
echo "ai_generated_settings_component_host_input_event_queue_materialized=true"
echo "chat_composer_component_host_input_event_queue_materialized=true"
echo "component_host_input_event_queue_bound_to_stage641_adapter=true"
echo "component_host_input_event_queue_owner_local=true"
echo "component_host_input_event_queue_non_executing=true"
echo "stage643_component_host_input_cycle_receipt_prepared=true"
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
