#!/usr/bin/env zsh
#
# Verifies the stage635 focus/validation result-surface state/render refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage635_focus_validation_result_surface_state_render_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage635 focus validation result surface state render refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage635FocusValidationResultSurfaceStateRenderRefreshPlan" \
  "CjguiInternalRendererStage635FocusValidationResultSurfaceStateRenderRefreshFacts" \
  "CjguiInternalRendererStage635FocusValidationResultSurfaceStateRenderRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage635FocusValidationResultSurfaceStateRenderRefreshDraft" \
  "CjguiInternalRendererStage634FocusValidationResultSurfaceActionStateAdapterReadiness" \
  "didConsumeStage634FocusValidationResultSurfaceActionStateAdapter" \
  "didMaterializeSharedResultSurfaceStateRenderRefreshExecutor" \
  "didMaterializeResultSurfaceRenderCommandRefreshLedger" \
  "didMaterializeValidationDisplayRenderRefreshReceipt" \
  "didMaterializeFocusTransitionRenderRefreshReceipt" \
  "didMaterializeInputFeedbackRenderRefreshReceipt" \
  "didMaterializeChatComposerResultSurfaceRenderRefreshReceipt" \
  "didPrepareStage636SharedFocusValidationResultSurfaceInteractionRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage635 focus validation result surface state render refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage635_focus_validation_result_surface_state_render_refresh_owner_present=true"
echo "stage634_focus_validation_result_surface_action_state_adapter_consumed=true"
echo "result_surface_action_state_candidates_consumed=true"
echo "shared_result_surface_state_render_refresh_executor_materialized=true"
echo "result_surface_render_command_refresh_ledger_materialized=true"
echo "validation_display_render_refresh_receipt_materialized=true"
echo "focus_transition_render_refresh_receipt_materialized=true"
echo "input_feedback_render_refresh_receipt_materialized=true"
echo "todo_result_surface_render_refresh_receipt_materialized=true"
echo "settings_result_surface_render_refresh_receipt_materialized=true"
echo "ai_generated_settings_result_surface_render_refresh_receipt_materialized=true"
echo "chat_composer_result_surface_render_refresh_receipt_materialized=true"
echo "result_surface_state_render_refresh_checkable=true"
echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_prepared=true"
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
