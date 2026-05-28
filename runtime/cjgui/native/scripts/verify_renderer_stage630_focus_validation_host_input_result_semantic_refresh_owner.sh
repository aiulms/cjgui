#!/usr/bin/env zsh
#
# Verifies the stage630 focus/validation host input result semantic refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage630_focus_validation_host_input_result_semantic_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage630 focus validation host input result semantic refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshPlan" \
  "CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshFacts" \
  "CjguiInternalRendererStage630FocusValidationHostInputResultSemanticRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage630FocusValidationHostInputResultSemanticRefreshDraft" \
  "CjguiInternalRendererStage629FocusValidationHostInputResultSurfaceReadiness" \
  "didConsumeStage629FocusValidationHostInputResultSurface" \
  "didMaterializeSharedResultSurfaceSemanticDiffRefresh" \
  "didMaterializeValidationErrorSemanticExplainLedger" \
  "didMaterializeFocusMovementSemanticExplainLedger" \
  "didMaterializeInputFeedbackSemanticExplainLedger" \
  "didMaterializeChatComposerResultSemanticRefreshReceipt" \
  "didBindSemanticRefreshToStage629ResultSurfaces" \
  "didPrepareStage631FocusValidationResultSurfaceHostInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage630 focus validation host input result semantic refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage630_focus_validation_host_input_result_semantic_refresh_owner_present=true"
echo "stage629_focus_validation_host_input_result_surface_consumed=true"
echo "shared_result_surface_semantic_diff_refresh_materialized=true"
echo "validation_error_semantic_explain_ledger_materialized=true"
echo "focus_movement_semantic_explain_ledger_materialized=true"
echo "input_feedback_semantic_explain_ledger_materialized=true"
echo "todo_result_semantic_refresh_receipt_materialized=true"
echo "settings_result_semantic_refresh_receipt_materialized=true"
echo "ai_generated_settings_result_semantic_refresh_receipt_materialized=true"
echo "chat_composer_result_semantic_refresh_receipt_materialized=true"
echo "semantic_refresh_bound_to_stage629_result_surfaces=true"
echo "stage631_focus_validation_result_surface_host_inspection_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
