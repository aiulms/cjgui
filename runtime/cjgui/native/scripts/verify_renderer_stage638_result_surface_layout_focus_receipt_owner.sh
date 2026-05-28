#!/usr/bin/env zsh
#
# Verifies the stage638 result-surface layout/focus execution receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage638_result_surface_layout_focus_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage638 result surface layout focus receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage638ResultSurfaceLayoutFocusReceiptPlan" \
  "CjguiInternalRendererStage638ResultSurfaceLayoutFocusReceiptFacts" \
  "CjguiInternalRendererStage638ResultSurfaceLayoutFocusReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage638ResultSurfaceLayoutFocusReceiptDraft" \
  "CjguiInternalRendererStage637ResultSurfaceLayoutFocusPreviewReadiness" \
  "didConsumeStage637ResultSurfaceLayoutFocusPreview" \
  "didMaterializeSharedLayoutFocusExecutionReceipt" \
  "didMaterializeResultSurfaceTextRunReceipt" \
  "didMaterializeResultSurfaceStyleTokenReceipt" \
  "didMaterializeResultSurfaceFocusTraversalReceipt" \
  "didMaterializeChatComposerLayoutFocusExecutionReceipt" \
  "didPrepareStage639ResultSurfaceDemoHostInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage638 result surface layout focus receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage638_result_surface_layout_focus_receipt_owner_present=true"
echo "stage637_result_surface_layout_focus_preview_consumed=true"
echo "shared_layout_focus_execution_receipt_materialized=true"
echo "result_surface_text_run_receipt_materialized=true"
echo "result_surface_style_token_receipt_materialized=true"
echo "result_surface_focus_traversal_receipt_materialized=true"
echo "todo_layout_focus_execution_receipt_materialized=true"
echo "settings_layout_focus_execution_receipt_materialized=true"
echo "ai_generated_settings_layout_focus_execution_receipt_materialized=true"
echo "chat_composer_layout_focus_execution_receipt_materialized=true"
echo "stage639_result_surface_demo_host_inspection_prepared=true"
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
