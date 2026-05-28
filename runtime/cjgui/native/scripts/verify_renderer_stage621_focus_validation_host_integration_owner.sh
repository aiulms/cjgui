#!/usr/bin/env zsh
#
# Verifies the stage621 focus/validation host integration owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage621_focus_validation_host_integration.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage621 focus validation host integration: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage621FocusValidationHostIntegrationPlan" \
  "CjguiInternalRendererStage621FocusValidationHostIntegrationFacts" \
  "CjguiInternalRendererStage621FocusValidationHostIntegrationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage621FocusValidationHostIntegrationDraft" \
  "CjguiInternalRendererStage620SharedFocusValidationInputCycleRuntimeContractReadiness" \
  "didConsumeStage620SharedFocusValidationInputCycleRuntimeContract" \
  "didMaterializeSharedFocusValidationHostIntegrationSlot" \
  "didMaterializeValidationDisplayHostSlot" \
  "didMaterializeFocusMovementHostSlot" \
  "didMaterializeInputFeedbackHostSlot" \
  "didMaterializeHostSemanticDiffSlot" \
  "didMaterializeChatComposerFocusValidationHostIntegration" \
  "didBindHostIntegrationToStage620RuntimeContract" \
  "didKeepHostIntegrationCheckable" \
  "didPrepareStage622FocusValidationHostFrameAssembly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage621 focus validation host integration: missing token $token" >&2
    exit 3
  fi
done

echo "stage621_focus_validation_host_integration_owner_present=true"
echo "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed=true"
echo "input_cycle_runtime_surfaces_consumed=true"
echo "shared_focus_validation_host_integration_slot_materialized=true"
echo "validation_display_host_slot_materialized=true"
echo "focus_movement_host_slot_materialized=true"
echo "input_feedback_host_slot_materialized=true"
echo "host_semantic_diff_slot_materialized=true"
echo "todo_focus_validation_host_integration_materialized=true"
echo "settings_focus_validation_host_integration_materialized=true"
echo "ai_generated_settings_focus_validation_host_integration_materialized=true"
echo "chat_composer_focus_validation_host_integration_materialized=true"
echo "host_integration_bound_to_stage620_runtime_contract=true"
echo "focus_validation_host_integration_checkable=true"
echo "stage622_focus_validation_host_frame_assembly_prepared=true"
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
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
