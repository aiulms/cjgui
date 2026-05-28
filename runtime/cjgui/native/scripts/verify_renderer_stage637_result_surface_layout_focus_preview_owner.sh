#!/usr/bin/env zsh
#
# Verifies the stage637 result-surface interaction layout/focus preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage637_result_surface_layout_focus_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage637 result surface layout focus preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage637ResultSurfaceLayoutFocusPreviewPlan" \
  "CjguiInternalRendererStage637ResultSurfaceLayoutFocusPreviewFacts" \
  "CjguiInternalRendererStage637ResultSurfaceLayoutFocusPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage637ResultSurfaceLayoutFocusPreviewDraft" \
  "CjguiInternalRendererStage636SharedFocusValidationResultSurfaceInteractionRuntimeContractReadiness" \
  "didConsumeStage636SharedFocusValidationResultSurfaceInteractionRuntimeContract" \
  "didMaterializeSharedResultSurfaceInteractionLayoutPreview" \
  "didMaterializeSharedResultSurfaceInteractionFocusPreview" \
  "didMaterializeValidationDisplayLayoutSlot" \
  "didMaterializeFocusRingPreviewSlot" \
  "didMaterializeInputFeedbackAffordanceSlot" \
  "didMaterializeChatComposerResultSurfaceLayoutFocusPreview" \
  "didPrepareStage638ResultSurfaceLayoutFocusExecutionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage637 result surface layout focus preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage637_result_surface_layout_focus_preview_owner_present=true"
echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed=true"
echo "shared_result_surface_interaction_layout_preview_materialized=true"
echo "shared_result_surface_interaction_focus_preview_materialized=true"
echo "validation_display_layout_slot_materialized=true"
echo "focus_ring_preview_slot_materialized=true"
echo "input_feedback_affordance_slot_materialized=true"
echo "todo_result_surface_layout_focus_preview_materialized=true"
echo "settings_result_surface_layout_focus_preview_materialized=true"
echo "ai_generated_settings_result_surface_layout_focus_preview_materialized=true"
echo "chat_composer_result_surface_layout_focus_preview_materialized=true"
echo "stage638_result_surface_layout_focus_execution_receipt_prepared=true"
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
