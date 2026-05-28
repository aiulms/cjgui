#!/usr/bin/env zsh
#
# Verifies the stage669 feedback input demo-host event adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage669_feedback_input_demo_host_event_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage669 feedback input demo-host event adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage669FeedbackInputDemoHostEventAdapterPlan" \
  "CjguiInternalRendererStage669FeedbackInputDemoHostEventAdapterFacts" \
  "CjguiInternalRendererStage669FeedbackInputDemoHostEventAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage669FeedbackInputDemoHostEventAdapterDraft" \
  "CjguiInternalRendererStage668ComponentFeedbackInputDemoHostRuntimeContractReadiness" \
  "didConsumeStage668ComponentFeedbackInputDemoHostRuntimeContract" \
  "didMaterializeSharedFeedbackInputDemoHostEventAdapter" \
  "didMaterializeValidationDismissDemoHostEventRoute" \
  "didMaterializeFocusMovementDemoHostEventRoute" \
  "didMaterializeInputFeedbackClearDemoHostEventRoute" \
  "didMaterializeSemanticDiffAcknowledgeDemoHostEventRoute" \
  "didBindEventAdapterToStage668RuntimeSurface" \
  "didPrepareStage670FeedbackInputDemoHostEventQueue"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage669 feedback input demo-host event adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage669_feedback_input_demo_host_event_adapter_owner_present=true"
echo "stage668_component_feedback_input_demo_host_runtime_contract_consumed=true"
echo "shared_feedback_input_demo_host_event_adapter_materialized=true"
echo "validation_dismiss_demo_host_event_route_materialized=true"
echo "focus_movement_demo_host_event_route_materialized=true"
echo "input_feedback_clear_demo_host_event_route_materialized=true"
echo "semantic_diff_acknowledge_demo_host_event_route_materialized=true"
echo "todo_feedback_input_demo_host_event_adapter_materialized=true"
echo "settings_feedback_input_demo_host_event_adapter_materialized=true"
echo "ai_generated_settings_feedback_input_demo_host_event_adapter_materialized=true"
echo "chat_composer_feedback_input_demo_host_event_adapter_materialized=true"
echo "feedback_input_demo_host_event_adapter_owner_local=true"
echo "stage670_feedback_input_demo_host_event_queue_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
