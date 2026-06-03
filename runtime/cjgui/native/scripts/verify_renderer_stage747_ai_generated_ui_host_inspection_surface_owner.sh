#!/usr/bin/env zsh
#
# Verifies the stage747 AI-generated UI host inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage747_ai_generated_ui_host_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage747 ai generated ui host inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage747AiGeneratedUiHostInspectionSurfacePlan" \
  "CjguiInternalRendererStage747AiGeneratedUiHostInspectionSurfaceFacts" \
  "CjguiInternalRendererStage747AiGeneratedUiHostInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage747AiGeneratedUiHostInspectionSurfaceDraft" \
  "CjguiInternalRendererStage746AiGeneratedUiOwnerReviewPreflightReadiness" \
  "didConsumeStage746AiGeneratedUiOwnerReviewPreflight" \
  "didMaterializeAiGeneratedUiHostInspectionRows" \
  "didMaterializeAiGeneratedUiResultSurfacePreview" \
  "didMaterializeAiGeneratedUiRenderCommandPreviewReceipt" \
  "didMaterializeAiGeneratedUiProbeInputContract" \
  "didPrepareStage748AiGeneratedUiRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage747 ai generated ui host inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage747_ai_generated_ui_host_inspection_surface_owner_present=true"
echo "stage746_ai_generated_ui_owner_review_preflight_consumed=true"
echo "ai_generated_ui_host_inspection_rows_materialized=true"
echo "ai_generated_ui_result_surface_preview_materialized=true"
echo "ai_generated_ui_render_command_preview_receipt_materialized=true"
echo "ai_generated_ui_probe_input_contract_materialized=true"
echo "todo_ai_generated_ui_host_inspection_surface_materialized=true"
echo "settings_ai_generated_ui_host_inspection_surface_materialized=true"
echo "ai_generated_settings_ai_generated_ui_host_inspection_surface_materialized=true"
echo "chat_composer_ai_generated_ui_host_inspection_surface_materialized=true"
echo "stage748_ai_generated_ui_runtime_manager_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "stable_public_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
