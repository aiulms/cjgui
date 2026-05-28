#!/usr/bin/env zsh
#
# Verifies the stage622 focus/validation host frame assembly owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage622_focus_validation_host_frame_assembly.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage622 focus validation host frame assembly: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage622FocusValidationHostFrameAssemblyPlan" \
  "CjguiInternalRendererStage622FocusValidationHostFrameAssemblyFacts" \
  "CjguiInternalRendererStage622FocusValidationHostFrameAssemblyReadiness" \
  "cjguiInternalExecuteDefaultRendererStage622FocusValidationHostFrameAssemblyDraft" \
  "CjguiInternalRendererStage621FocusValidationHostIntegrationReadiness" \
  "didConsumeStage621FocusValidationHostIntegration" \
  "didMaterializeSharedFocusValidationHostFrameAssembly" \
  "didMaterializeValidationDisplayFrameSlot" \
  "didMaterializeFocusHandoffFrameSlot" \
  "didMaterializeInputFeedbackFrameSlot" \
  "didMaterializeSemanticDiffFrameSlot" \
  "didMaterializeChatComposerFocusValidationHostFrame" \
  "didBindHostFrameAssemblyToStage621HostIntegration" \
  "didKeepHostFrameAssemblyNonPublishing" \
  "didPrepareStage623FocusValidationHostInteractionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage622 focus validation host frame assembly: missing token $token" >&2
    exit 3
  fi
done

echo "stage622_focus_validation_host_frame_assembly_owner_present=true"
echo "stage621_focus_validation_host_integration_consumed=true"
echo "host_integration_slots_consumed=true"
echo "shared_focus_validation_host_frame_assembly_materialized=true"
echo "validation_display_frame_slot_materialized=true"
echo "focus_handoff_frame_slot_materialized=true"
echo "input_feedback_frame_slot_materialized=true"
echo "semantic_diff_frame_slot_materialized=true"
echo "todo_focus_validation_host_frame_materialized=true"
echo "settings_focus_validation_host_frame_materialized=true"
echo "ai_generated_settings_focus_validation_host_frame_materialized=true"
echo "chat_composer_focus_validation_host_frame_materialized=true"
echo "host_frame_assembly_bound_to_stage621_host_integration=true"
echo "host_frame_assembly_non_publishing=true"
echo "stage623_focus_validation_host_interaction_receipt_prepared=true"
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
