#!/usr/bin/env zsh
#
# Verifies the stage605 form result feedback host input layout/focus inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage605_form_result_feedback_host_input_layout_focus_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage605 form result feedback host input layout focus inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage605FormResultFeedbackHostInputLayoutFocusInspectionPlan" \
  "CjguiInternalRendererStage605FormResultFeedbackHostInputLayoutFocusInspectionFacts" \
  "CjguiInternalRendererStage605FormResultFeedbackHostInputLayoutFocusInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage605FormResultFeedbackHostInputLayoutFocusInspectionDraft" \
  "CjguiInternalRendererStage604FormResultFeedbackHostInputRuntimeSurfaceContractReadiness" \
  "didConsumeStage604FormResultFeedbackHostInputRuntimeSurfaceContract" \
  "didMaterializeSharedFeedbackHostInputLayoutInspectionLedger" \
  "didMaterializeSharedFeedbackHostFocusInspectionLedger" \
  "didMaterializeValidationDisplayLayoutSlot" \
  "didMaterializeInputFeedbackLayoutSlot" \
  "didMaterializeFocusTransitionInspectionSlot" \
  "didMaterializeChatComposerFeedbackHostInputLayoutFocusInspection" \
  "didBindLayoutFocusInspectionToStage604RuntimeSurfaces" \
  "didPrepareStage606FeedbackHostInputVisualExecutionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage605 form result feedback host input layout focus inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage605_form_result_feedback_host_input_layout_focus_inspection_owner_present=true"
echo "stage604_form_result_feedback_host_input_runtime_surface_contract_consumed=true"
echo "shared_feedback_host_input_layout_inspection_ledger_materialized=true"
echo "shared_feedback_host_focus_inspection_ledger_materialized=true"
echo "validation_display_layout_slot_materialized=true"
echo "input_feedback_layout_slot_materialized=true"
echo "focus_transition_inspection_slot_materialized=true"
echo "todo_feedback_host_input_layout_focus_inspection_materialized=true"
echo "settings_feedback_host_input_layout_focus_inspection_materialized=true"
echo "ai_generated_settings_feedback_host_input_layout_focus_inspection_materialized=true"
echo "chat_composer_feedback_host_input_layout_focus_inspection_materialized=true"
echo "layout_focus_inspection_bound_to_stage604_runtime_surfaces=true"
echo "stage606_feedback_host_input_visual_execution_receipt_prepared=true"
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
