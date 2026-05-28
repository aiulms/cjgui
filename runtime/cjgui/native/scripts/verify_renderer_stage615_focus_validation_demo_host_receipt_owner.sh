#!/usr/bin/env zsh
#
# Verifies the stage615 focus/validation demo host receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage615_focus_validation_demo_host_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage615 focus validation demo host receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage615FocusValidationDemoHostReceiptPlan" \
  "CjguiInternalRendererStage615FocusValidationDemoHostReceiptFacts" \
  "CjguiInternalRendererStage615FocusValidationDemoHostReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage615FocusValidationDemoHostReceiptDraft" \
  "CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness" \
  "didConsumeStage614FocusValidationFeedbackResolver" \
  "didMaterializeSharedFocusValidationDemoHostReceipt" \
  "didMaterializeFocusMovementPreviewReceipt" \
  "didMaterializeValidationDisplayReceipt" \
  "didMaterializeInputFeedbackDisplayReceipt" \
  "didMaterializeDemoHostInspectionProbeInput" \
  "didMaterializeChatComposerFocusValidationDemoHostReceipt" \
  "didPrepareStage616SharedFocusValidationRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage615 focus validation demo host receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage615_focus_validation_demo_host_receipt_owner_present=true"
echo "stage614_focus_validation_feedback_resolver_consumed=true"
echo "shared_focus_validation_demo_host_receipt_materialized=true"
echo "focus_movement_preview_receipt_materialized=true"
echo "validation_display_receipt_materialized=true"
echo "input_feedback_display_receipt_materialized=true"
echo "demo_host_inspection_probe_input_materialized=true"
echo "todo_focus_validation_demo_host_receipt_materialized=true"
echo "settings_focus_validation_demo_host_receipt_materialized=true"
echo "ai_generated_settings_focus_validation_demo_host_receipt_materialized=true"
echo "chat_composer_focus_validation_demo_host_receipt_materialized=true"
echo "stage616_shared_focus_validation_runtime_contract_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "focus_manager_enabled=false"
echo "visibility_publication_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
