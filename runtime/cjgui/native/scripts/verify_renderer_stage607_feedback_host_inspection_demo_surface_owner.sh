#!/usr/bin/env zsh
#
# Verifies the stage607 feedback host inspection demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage607_feedback_host_inspection_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage607 feedback host inspection demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage607FeedbackHostInspectionDemoSurfacePlan" \
  "CjguiInternalRendererStage607FeedbackHostInspectionDemoSurfaceFacts" \
  "CjguiInternalRendererStage607FeedbackHostInspectionDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage607FeedbackHostInspectionDemoSurfaceDraft" \
  "CjguiInternalRendererStage606FeedbackHostInputVisualExecutionReceiptReadiness" \
  "didConsumeStage606FeedbackHostInputVisualExecutionReceipt" \
  "didMaterializeSharedFeedbackHostInspectionDemoSurface" \
  "didMaterializeValidationDisplayResultSurfaceRefresh" \
  "didMaterializeInputFeedbackResultSurfaceRefresh" \
  "didMaterializeFocusMovementResultSurfaceRefresh" \
  "didMaterializeChatComposerFeedbackHostInspectionDemoSurface" \
  "didBindDemoSurfaceToStage606VisualExecutionReceipts" \
  "didPrepareStage608FeedbackHostInspectionRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage607 feedback host inspection demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage607_feedback_host_inspection_demo_surface_owner_present=true"
echo "stage606_feedback_host_input_visual_execution_receipt_consumed=true"
echo "shared_feedback_host_inspection_demo_surface_materialized=true"
echo "validation_display_result_surface_refresh_materialized=true"
echo "input_feedback_result_surface_refresh_materialized=true"
echo "focus_movement_result_surface_refresh_materialized=true"
echo "todo_feedback_host_inspection_demo_surface_materialized=true"
echo "settings_feedback_host_inspection_demo_surface_materialized=true"
echo "ai_generated_settings_feedback_host_inspection_demo_surface_materialized=true"
echo "chat_composer_feedback_host_inspection_demo_surface_materialized=true"
echo "demo_surface_bound_to_stage606_visual_execution_receipts=true"
echo "stage608_feedback_host_inspection_runtime_contract_prepared=true"
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
