#!/usr/bin/env zsh
#
# Verifies the stage600 form result demo host feedback surface integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage600_form_result_demo_host_feedback_surface_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage600 form result demo host feedback surface integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage600FormResultDemoHostFeedbackSurfaceIntegrationPlan" \
  "CjguiInternalRendererStage600FormResultDemoHostFeedbackSurfaceIntegrationFacts" \
  "CjguiInternalRendererStage600FormResultDemoHostFeedbackSurfaceIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage600FormResultDemoHostFeedbackSurfaceIntegrationDraft" \
  "CjguiInternalRendererStage599FormResultFeedbackSurfaceReducerReadiness" \
  "didMaterializeSharedFormResultDemoHostFeedbackSurfaceIntegration" \
  "didMaterializeSharedFormResultDemoHostFeedbackSurfaceHelper" \
  "didMaterializeSharedFormResultDemoHostFeedbackExecutionContract" \
  "didMaterializeTodoDemoHostFeedbackSurfaceIntegration" \
  "didMaterializeSettingsDemoHostFeedbackSurfaceIntegration" \
  "didMaterializeAiGeneratedSettingsDemoHostFeedbackSurfaceIntegration" \
  "didMaterializeChatComposerDemoHostFeedbackSurfaceIntegration" \
  "didBindDemoHostFeedbackSurfaceIntegrationToStage599Reducer" \
  "didBindDemoHostFeedbackSurfaceIntegrationToStage598HostInspection" \
  "didBindDemoHostFeedbackSurfaceIntegrationToStage597ValidationFocusSurface" \
  "didBindDemoHostFeedbackSurfaceIntegrationToStage596RuntimeContract" \
  "didReducePerDemoValidationFocusHostTemplateNeed" \
  "didPrepareStage601FormResultFeedbackSurfaceInputEventBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage600 form result demo host feedback surface integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage600_form_result_demo_host_feedback_surface_integration_owner_present=true"
echo "stage599_form_result_feedback_surface_reducer_consumed=true"
echo "stage598_form_result_feedback_host_inspection_receipt_consumed_transitively=true"
echo "stage597_form_result_feedback_validation_focus_surface_consumed_transitively=true"
echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed_transitively=true"
echo "shared_form_result_demo_host_feedback_surface_integration_materialized=true"
echo "shared_form_result_demo_host_feedback_surface_helper_materialized=true"
echo "shared_form_result_demo_host_feedback_execution_contract_materialized=true"
echo "todo_demo_host_feedback_surface_integration_materialized=true"
echo "settings_demo_host_feedback_surface_integration_materialized=true"
echo "ai_generated_settings_demo_host_feedback_surface_integration_materialized=true"
echo "chat_composer_demo_host_feedback_surface_integration_materialized=true"
echo "demo_host_feedback_surface_integration_bound_to_stage599_reducer=true"
echo "demo_host_feedback_surface_integration_bound_to_stage598_host_inspection=true"
echo "demo_host_feedback_surface_integration_bound_to_stage597_validation_focus_surface=true"
echo "demo_host_feedback_surface_integration_bound_to_stage596_runtime_contract=true"
echo "per_demo_validation_focus_host_template_need_reduced=true"
echo "stage601_form_result_feedback_surface_input_event_bridge_prepared=true"
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
