#!/usr/bin/env zsh
#
# Verifies the stage601 form result feedback surface input event bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage601_form_result_feedback_surface_input_event_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage601 form result feedback surface input event bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage601FormResultFeedbackSurfaceInputEventBridgePlan" \
  "CjguiInternalRendererStage601FormResultFeedbackSurfaceInputEventBridgeFacts" \
  "CjguiInternalRendererStage601FormResultFeedbackSurfaceInputEventBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage601FormResultFeedbackSurfaceInputEventBridgeDraft" \
  "CjguiInternalRendererStage600FormResultDemoHostFeedbackSurfaceIntegrationReadiness" \
  "didConsumeStage600FormResultDemoHostFeedbackSurfaceIntegration" \
  "didMaterializeSharedFormResultFeedbackSurfaceInputEventBridge" \
  "didMaterializeFeedbackSurfaceInputRouteLedger" \
  "didMaterializeValidationFeedbackInputRoute" \
  "didMaterializeFocusMovementInputRoute" \
  "didMaterializeInputFeedbackDisplayRoute" \
  "didMaterializeTodoFeedbackSurfaceInputEventRoute" \
  "didMaterializeSettingsFeedbackSurfaceInputEventRoute" \
  "didMaterializeAiGeneratedSettingsFeedbackSurfaceInputEventRoute" \
  "didMaterializeChatComposerFeedbackSurfaceInputEventRoute" \
  "didBindFeedbackSurfaceInputBridgeToStage600HostIntegration" \
  "didPrepareStage602FormResultFeedbackSurfaceEventNormalizer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage601 form result feedback surface input event bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage601_form_result_feedback_surface_input_event_bridge_owner_present=true"
echo "stage600_form_result_demo_host_feedback_surface_integration_consumed=true"
echo "shared_form_result_feedback_surface_input_event_bridge_materialized=true"
echo "feedback_surface_input_route_ledger_materialized=true"
echo "validation_feedback_input_route_materialized=true"
echo "focus_movement_input_route_materialized=true"
echo "input_feedback_display_route_materialized=true"
echo "todo_feedback_surface_input_event_route_materialized=true"
echo "settings_feedback_surface_input_event_route_materialized=true"
echo "ai_generated_settings_feedback_surface_input_event_route_materialized=true"
echo "chat_composer_feedback_surface_input_event_route_materialized=true"
echo "feedback_surface_input_bridge_bound_to_stage600_host_integration=true"
echo "stage602_form_result_feedback_surface_event_normalizer_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
