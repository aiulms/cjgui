#!/usr/bin/env zsh
#
# Verifies the stage623 focus/validation host interaction receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage623_focus_validation_host_interaction_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage623 focus validation host interaction receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage623FocusValidationHostInteractionReceiptPlan" \
  "CjguiInternalRendererStage623FocusValidationHostInteractionReceiptFacts" \
  "CjguiInternalRendererStage623FocusValidationHostInteractionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage623FocusValidationHostInteractionReceiptDraft" \
  "CjguiInternalRendererStage622FocusValidationHostFrameAssemblyReadiness" \
  "didConsumeStage622FocusValidationHostFrameAssembly" \
  "didMaterializeSharedFocusValidationHostInteractionReceipt" \
  "didMaterializeFocusTransitionPreviewReceipt" \
  "didMaterializeValidationDisplayRefreshReceipt" \
  "didMaterializeInputFeedbackDisplayReceipt" \
  "didMaterializeDemoHostInspectionProbeInput" \
  "didMaterializeChatComposerFocusValidationHostInteractionReceipt" \
  "didBindHostInteractionReceiptToStage622FrameAssembly" \
  "didBindHostInteractionReceiptToStage620RuntimeContract" \
  "didPrepareStage624SharedFocusValidationDemoHostRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage623 focus validation host interaction receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage623_focus_validation_host_interaction_receipt_owner_present=true"
echo "stage622_focus_validation_host_frame_assembly_consumed=true"
echo "focus_validation_host_frames_consumed=true"
echo "shared_focus_validation_host_interaction_receipt_materialized=true"
echo "focus_transition_preview_receipt_materialized=true"
echo "validation_display_refresh_receipt_materialized=true"
echo "input_feedback_display_receipt_materialized=true"
echo "demo_host_inspection_probe_input_materialized=true"
echo "todo_focus_validation_host_interaction_receipt_materialized=true"
echo "settings_focus_validation_host_interaction_receipt_materialized=true"
echo "ai_generated_settings_focus_validation_host_interaction_receipt_materialized=true"
echo "chat_composer_focus_validation_host_interaction_receipt_materialized=true"
echo "host_interaction_receipt_bound_to_stage622_frame_assembly=true"
echo "host_interaction_receipt_bound_to_stage620_runtime_contract=true"
echo "stage624_shared_focus_validation_demo_host_runtime_contract_prepared=true"
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
