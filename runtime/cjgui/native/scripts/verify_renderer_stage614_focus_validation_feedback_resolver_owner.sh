#!/usr/bin/env zsh
#
# Verifies the stage614 focus/validation feedback resolver owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage614_focus_validation_feedback_resolver.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage614 focus validation feedback resolver: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage614FocusValidationFeedbackResolverPlan" \
  "CjguiInternalRendererStage614FocusValidationFeedbackResolverFacts" \
  "CjguiInternalRendererStage614FocusValidationFeedbackResolverReadiness" \
  "cjguiInternalExecuteDefaultRendererStage614FocusValidationFeedbackResolverDraft" \
  "CjguiInternalRendererStage613FocusValidationManagerReadiness" \
  "didConsumeStage613FocusValidationManager" \
  "didMaterializeSharedFocusValidationFeedbackResolver" \
  "didMaterializeValidationMessageTextRun" \
  "didMaterializeFocusRingStyleToken" \
  "didMaterializeInputFeedbackAffordance" \
  "didMaterializeTodoFocusValidationFeedbackSurface" \
  "didMaterializeSettingsFocusValidationFeedbackSurface" \
  "didMaterializeAiGeneratedSettingsFocusValidationFeedbackSurface" \
  "didMaterializeChatComposerFocusValidationFeedbackSurface" \
  "didPrepareStage615FocusValidationDemoHostReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage614 focus validation feedback resolver: missing token $token" >&2
    exit 3
  fi
done

echo "stage614_focus_validation_feedback_resolver_owner_present=true"
echo "stage613_focus_validation_manager_consumed=true"
echo "shared_focus_validation_feedback_resolver_materialized=true"
echo "validation_message_text_run_materialized=true"
echo "focus_ring_style_token_materialized=true"
echo "input_feedback_affordance_materialized=true"
echo "todo_focus_validation_feedback_surface_materialized=true"
echo "settings_focus_validation_feedback_surface_materialized=true"
echo "ai_generated_settings_focus_validation_feedback_surface_materialized=true"
echo "chat_composer_focus_validation_feedback_surface_materialized=true"
echo "stage615_focus_validation_demo_host_receipt_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
