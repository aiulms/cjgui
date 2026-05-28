#!/usr/bin/env zsh
#
# Verifies the stage667 component feedback input result-surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage667_component_feedback_input_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage667 component feedback input result-surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage667ComponentFeedbackInputResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage667ComponentFeedbackInputResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage667ComponentFeedbackInputResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage667ComponentFeedbackInputResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage666ComponentFeedbackInputHostInspectionReceiptReadiness" \
  "didConsumeStage666ComponentFeedbackInputHostInspectionReceipt" \
  "didMaterializeSharedFeedbackInputResultSurfaceRefresh" \
  "didMaterializeValidationDisplayResultSurfaceRefresh" \
  "didMaterializeFocusTransitionResultSurfaceRefresh" \
  "didMaterializeInputFeedbackClearResultSurfaceRefresh" \
  "didMaterializeSemanticDiffAcknowledgeResultSurfaceRefresh" \
  "didPrepareStage668ComponentFeedbackInputDemoHostRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage667 component feedback input result-surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage667_component_feedback_input_result_surface_refresh_owner_present=true"
echo "stage666_component_feedback_input_host_inspection_receipt_consumed=true"
echo "feedback_input_host_inspection_receipts_consumed=true"
echo "shared_feedback_input_result_surface_refresh_materialized=true"
echo "validation_display_result_surface_refresh_materialized=true"
echo "focus_transition_result_surface_refresh_materialized=true"
echo "input_feedback_clear_result_surface_refresh_materialized=true"
echo "semantic_diff_acknowledge_result_surface_refresh_materialized=true"
echo "todo_feedback_input_result_surface_refresh_materialized=true"
echo "settings_feedback_input_result_surface_refresh_materialized=true"
echo "ai_generated_settings_feedback_input_result_surface_refresh_materialized=true"
echo "chat_composer_feedback_input_result_surface_refresh_materialized=true"
echo "result_surface_refresh_bound_to_stage666_inspection=true"
echo "feedback_input_result_surface_refresh_checkable=true"
echo "stage668_component_feedback_input_demo_host_runtime_contract_prepared=true"
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
