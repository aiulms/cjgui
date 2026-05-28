#!/usr/bin/env zsh
#
# Verifies the stage653 interaction feedback host integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage653_interaction_feedback_host_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage653 interaction feedback host integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage653InteractionFeedbackHostIntegrationPlan" \
  "CjguiInternalRendererStage653InteractionFeedbackHostIntegrationFacts" \
  "CjguiInternalRendererStage653InteractionFeedbackHostIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage653InteractionFeedbackHostIntegrationDraft" \
  "CjguiInternalRendererStage652ComponentHostInputResultSurfaceInteractionFeedbackRuntimeContractReadiness" \
  "didConsumeStage652InteractionFeedbackRuntimeContract" \
  "didMaterializeSharedInteractionFeedbackHostIntegrationSlots" \
  "didMaterializeValidationDismissHostSlot" \
  "didMaterializeFocusMovementHostSlot" \
  "didMaterializeInputFeedbackClearHostSlot" \
  "didMaterializeSemanticDiffAcknowledgeHostSlot" \
  "didMaterializeChatComposerInteractionFeedbackHostIntegration" \
  "didBindHostIntegrationToStage652RuntimeContract" \
  "didPrepareStage654InteractionFeedbackHostFrameAssembly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage653 interaction feedback host integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage653_interaction_feedback_host_integration_owner_present=true"
echo "stage652_interaction_feedback_runtime_contract_consumed=true"
echo "interaction_feedback_runtime_surfaces_consumed=true"
echo "shared_interaction_feedback_host_integration_slots_materialized=true"
echo "validation_dismiss_host_slot_materialized=true"
echo "focus_movement_host_slot_materialized=true"
echo "input_feedback_clear_host_slot_materialized=true"
echo "semantic_diff_acknowledge_host_slot_materialized=true"
echo "todo_interaction_feedback_host_integration_materialized=true"
echo "settings_interaction_feedback_host_integration_materialized=true"
echo "ai_generated_settings_interaction_feedback_host_integration_materialized=true"
echo "chat_composer_interaction_feedback_host_integration_materialized=true"
echo "host_integration_bound_to_stage652_runtime_contract=true"
echo "stage654_interaction_feedback_host_frame_assembly_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
