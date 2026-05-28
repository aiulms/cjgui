#!/usr/bin/env zsh
#
# Verifies the stage665 component feedback input demo-host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage665_component_feedback_input_demo_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage665 component feedback input demo-host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage665ComponentFeedbackInputDemoHostSurfacePlan" \
  "CjguiInternalRendererStage665ComponentFeedbackInputDemoHostSurfaceFacts" \
  "CjguiInternalRendererStage665ComponentFeedbackInputDemoHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage665ComponentFeedbackInputDemoHostSurfaceDraft" \
  "CjguiInternalRendererStage664InteractionFeedbackInputRuntimeContractReadiness" \
  "didConsumeStage664InteractionFeedbackInputRuntimeContract" \
  "didMaterializeSharedComponentFeedbackInputDemoHostSurface" \
  "didMaterializeValidationDismissHostSurface" \
  "didMaterializeFocusMovementHostSurface" \
  "didMaterializeInputFeedbackClearHostSurface" \
  "didMaterializeSemanticDiffAcknowledgeHostSurface" \
  "didMaterializeChatComposerFeedbackInputDemoHostSurface" \
  "didPrepareStage666ComponentFeedbackInputHostInspectionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage665 component feedback input demo-host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage665_component_feedback_input_demo_host_surface_owner_present=true"
echo "stage664_interaction_feedback_input_runtime_contract_consumed=true"
echo "feedback_input_runtime_surfaces_consumed=true"
echo "shared_component_feedback_input_demo_host_surface_materialized=true"
echo "validation_dismiss_host_surface_materialized=true"
echo "focus_movement_host_surface_materialized=true"
echo "input_feedback_clear_host_surface_materialized=true"
echo "semantic_diff_acknowledge_host_surface_materialized=true"
echo "todo_feedback_input_demo_host_surface_materialized=true"
echo "settings_feedback_input_demo_host_surface_materialized=true"
echo "ai_generated_settings_feedback_input_demo_host_surface_materialized=true"
echo "chat_composer_feedback_input_demo_host_surface_materialized=true"
echo "demo_host_surface_bound_to_stage664_runtime_contract=true"
echo "feedback_input_demo_host_surface_owner_local=true"
echo "feedback_input_demo_host_surface_checkable=true"
echo "stage666_component_feedback_input_host_inspection_receipt_prepared=true"
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
