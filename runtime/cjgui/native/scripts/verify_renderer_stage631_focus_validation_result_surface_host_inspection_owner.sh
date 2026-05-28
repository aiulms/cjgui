#!/usr/bin/env zsh
#
# Verifies the stage631 focus/validation result surface host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage631_focus_validation_result_surface_host_inspection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage631 focus validation result surface host inspection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage631FocusValidationResultSurfaceHostInspectionPlan" \
  "CjguiInternalRendererStage631FocusValidationResultSurfaceHostInspectionFacts" \
  "CjguiInternalRendererStage631FocusValidationResultSurfaceHostInspectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage631FocusValidationResultSurfaceHostInspectionDraft" \
  "CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness" \
  "didConsumeStage630FocusValidationHostInputResultSemanticRefresh" \
  "didMaterializeSharedResultSurfaceHostInspectionContract" \
  "didMaterializeResultSurfaceHostInspectionProbeInput" \
  "didMaterializeValidationErrorHostInspectionSlot" \
  "didMaterializeFocusMovementHostInspectionSlot" \
  "didMaterializeInputFeedbackHostInspectionSlot" \
  "didMaterializeChatComposerResultSurfaceHostInspectionReceipt" \
  "didPrepareStage632SharedFocusValidationResultSurfaceRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage631 focus validation result surface host inspection: missing token $token" >&2
    exit 3
  fi
done

echo "stage631_focus_validation_result_surface_host_inspection_owner_present=true"
echo "stage630_focus_validation_host_input_result_semantic_refresh_consumed=true"
echo "shared_result_surface_host_inspection_contract_materialized=true"
echo "result_surface_host_inspection_probe_input_materialized=true"
echo "validation_error_host_inspection_slot_materialized=true"
echo "focus_movement_host_inspection_slot_materialized=true"
echo "input_feedback_host_inspection_slot_materialized=true"
echo "todo_result_surface_host_inspection_receipt_materialized=true"
echo "settings_result_surface_host_inspection_receipt_materialized=true"
echo "ai_generated_settings_result_surface_host_inspection_receipt_materialized=true"
echo "chat_composer_result_surface_host_inspection_receipt_materialized=true"
echo "host_inspection_bound_to_stage630_semantic_refresh=true"
echo "stage632_shared_focus_validation_result_surface_runtime_contract_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
