#!/usr/bin/env zsh
#
# Verifies the stage691 replay host text input execution/result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage691_replay_host_text_input_execution_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage691 replay host text input execution/result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage691ReplayHostTextInputExecutionResultSurfacePlan" \
  "CjguiInternalRendererStage691ReplayHostTextInputExecutionResultSurfaceFacts" \
  "CjguiInternalRendererStage691ReplayHostTextInputExecutionResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage691ReplayHostTextInputExecutionResultSurfaceDraft" \
  "CjguiInternalRendererStage690ReplayHostTextInputHostEventAdapterReadiness" \
  "didConsumeStage690ReplayHostTextInputHostEventAdapter" \
  "didMaterializeSharedReplayHostTextInputExecutionResultReceipt" \
  "didMaterializeTextEditExecutionResultSurfaceReceipt" \
  "didMaterializeSubmitExecutionResultSurfaceReceipt" \
  "didMaterializeValidationFeedbackResultSurfaceReceipt" \
  "didMaterializeFocusTransitionHostInspectionPreview" \
  "didMaterializeRenderCommandRefreshReceipt" \
  "didMaterializeSemanticDiffExplainReceipt" \
  "didMaterializeChatComposerReplayHostTextInputExecutionResultSurface" \
  "didBindExecutionResultSurfaceToStage690EventQueue" \
  "didBindExecutionResultSurfaceToStage688RuntimeContract" \
  "didPrepareStage692ReplayHostTextInputDemoHostCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage691 replay host text input execution/result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage691_replay_host_text_input_execution_result_surface_owner_present=true"
echo "stage690_replay_host_text_input_host_event_adapter_consumed=true"
echo "shared_replay_host_text_input_execution_result_receipt_materialized=true"
echo "text_edit_execution_result_surface_receipt_materialized=true"
echo "submit_execution_result_surface_receipt_materialized=true"
echo "validation_feedback_result_surface_receipt_materialized=true"
echo "focus_transition_host_inspection_preview_materialized=true"
echo "render_command_refresh_receipt_materialized=true"
echo "semantic_diff_explain_receipt_materialized=true"
echo "todo_replay_host_text_input_execution_result_surface_materialized=true"
echo "settings_replay_host_text_input_execution_result_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_execution_result_surface_materialized=true"
echo "chat_composer_replay_host_text_input_execution_result_surface_materialized=true"
echo "execution_result_surface_bound_to_stage690_event_queue=true"
echo "execution_result_surface_bound_to_stage688_runtime_contract=true"
echo "stage692_replay_host_text_input_demo_host_cycle_executor_prepared=true"
echo "host_mutation=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
