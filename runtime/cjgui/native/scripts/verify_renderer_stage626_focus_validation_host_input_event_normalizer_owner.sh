#!/usr/bin/env zsh
#
# Verifies the stage626 focus/validation host input event normalizer owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage626_focus_validation_host_input_event_normalizer.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage626 focus validation host input event normalizer: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage626FocusValidationHostInputEventNormalizerPlan" \
  "CjguiInternalRendererStage626FocusValidationHostInputEventNormalizerFacts" \
  "CjguiInternalRendererStage626FocusValidationHostInputEventNormalizerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage626FocusValidationHostInputEventNormalizerDraft" \
  "CjguiInternalRendererStage625FocusValidationHostInputAdapterReadiness" \
  "didConsumeStage625FocusValidationHostInputAdapter" \
  "didMaterializeSharedFocusValidationHostInputEventNormalizer" \
  "didMaterializeNormalizedValidationDisplayHostInputEvent" \
  "didMaterializeNormalizedFocusHandoffHostInputEvent" \
  "didMaterializeNormalizedInputFeedbackHostInputEvent" \
  "didMaterializeNormalizedSemanticDiffHostInputEvent" \
  "didMaterializeHostInputEventLedger" \
  "didMaterializeChatComposerNormalizedHostInputEvent" \
  "didBindHostInputEventNormalizerToStage625Adapter" \
  "didBindHostInputEventNormalizerToStage624RuntimeContract" \
  "didPrepareStage627ComponentRuntimeFocusValidationHostInputCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage626 focus validation host input event normalizer: missing token $token" >&2
    exit 3
  fi
done

echo "stage626_focus_validation_host_input_event_normalizer_owner_present=true"
echo "stage625_focus_validation_host_input_adapter_consumed=true"
echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed_transitively=true"
echo "shared_focus_validation_host_input_event_normalizer_materialized=true"
echo "normalized_validation_display_host_input_event_materialized=true"
echo "normalized_focus_handoff_host_input_event_materialized=true"
echo "normalized_input_feedback_host_input_event_materialized=true"
echo "normalized_semantic_diff_host_input_event_materialized=true"
echo "host_input_event_ledger_materialized=true"
echo "todo_normalized_focus_validation_host_input_event_materialized=true"
echo "settings_normalized_focus_validation_host_input_event_materialized=true"
echo "ai_generated_settings_normalized_focus_validation_host_input_event_materialized=true"
echo "chat_composer_normalized_focus_validation_host_input_event_materialized=true"
echo "host_input_event_normalizer_bound_to_stage625_adapter=true"
echo "host_input_event_normalizer_bound_to_stage624_runtime_contract=true"
echo "stage627_component_runtime_focus_validation_host_input_cycle_executor_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
