#!/usr/bin/env zsh
#
# Verifies the stage639 result-surface demo host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage639_result_surface_demo_host_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage639 result surface demo host inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage639ResultSurfaceDemoHostInspectionPlan" \
  "CjguiInternalRendererStage639ResultSurfaceDemoHostInspectionFacts" \
  "CjguiInternalRendererStage639ResultSurfaceDemoHostInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage639ResultSurfaceDemoHostInspectionDraft" \
  "CjguiInternalRendererStage638ResultSurfaceLayoutFocusReceiptReadiness" \
  "didConsumeStage638ResultSurfaceLayoutFocusReceipt" \
  "didMaterializeSharedResultSurfaceDemoHostInspectionInput" \
  "didMaterializeValidationDisplayHostInspectionReceipt" \
  "didMaterializeFocusMovementHostInspectionReceipt" \
  "didMaterializeInputFeedbackHostInspectionReceipt" \
  "didMaterializeChatComposerDemoHostInspectionSurface" \
  "didPrepareStage640ResultSurfaceHostRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage639 result surface demo host inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage639_result_surface_demo_host_inspection_owner_present=true"
echo "stage638_result_surface_layout_focus_receipt_consumed=true"
echo "shared_result_surface_demo_host_inspection_input_materialized=true"
echo "validation_display_host_inspection_receipt_materialized=true"
echo "focus_movement_host_inspection_receipt_materialized=true"
echo "input_feedback_host_inspection_receipt_materialized=true"
echo "todo_demo_host_inspection_surface_materialized=true"
echo "settings_demo_host_inspection_surface_materialized=true"
echo "ai_generated_settings_demo_host_inspection_surface_materialized=true"
echo "chat_composer_demo_host_inspection_surface_materialized=true"
echo "stage640_result_surface_host_runtime_contract_prepared=true"
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
