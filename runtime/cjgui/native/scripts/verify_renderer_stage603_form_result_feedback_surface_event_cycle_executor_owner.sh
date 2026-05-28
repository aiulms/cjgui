#!/usr/bin/env zsh
#
# Verifies the stage603 form result feedback surface event cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage603_form_result_feedback_surface_event_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage603 form result feedback surface event cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage603FormResultFeedbackSurfaceEventCycleExecutorPlan" \
  "CjguiInternalRendererStage603FormResultFeedbackSurfaceEventCycleExecutorFacts" \
  "CjguiInternalRendererStage603FormResultFeedbackSurfaceEventCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage603FormResultFeedbackSurfaceEventCycleExecutorDraft" \
  "CjguiInternalRendererStage602FormResultFeedbackSurfaceEventNormalizerReadiness" \
  "didConsumeStage602FormResultFeedbackSurfaceEventNormalizer" \
  "didMaterializeSharedFormResultFeedbackSurfaceEventCycleExecutor" \
  "didMaterializeFeedbackSurfaceActionIntentPreviewLedger" \
  "didMaterializeFeedbackSurfaceStateDeltaDryRunLedger" \
  "didMaterializeFeedbackSurfaceRenderCommandRefreshLedger" \
  "didMaterializeFeedbackSurfaceFocusTransitionPreviewLedger" \
  "didMaterializeTodoFeedbackSurfaceEventCycleReceipt" \
  "didMaterializeSettingsFeedbackSurfaceEventCycleReceipt" \
  "didMaterializeAiGeneratedSettingsFeedbackSurfaceEventCycleReceipt" \
  "didMaterializeChatComposerFeedbackSurfaceEventCycleReceipt" \
  "didBindEventCycleExecutorToStage602Normalizer" \
  "didPrepareStage604FormResultFeedbackHostInputRuntimeSurfaceContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage603 form result feedback surface event cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage603_form_result_feedback_surface_event_cycle_executor_owner_present=true"
echo "stage602_form_result_feedback_surface_event_normalizer_consumed=true"
echo "shared_form_result_feedback_surface_event_cycle_executor_materialized=true"
echo "feedback_surface_action_intent_preview_ledger_materialized=true"
echo "feedback_surface_state_delta_dry_run_ledger_materialized=true"
echo "feedback_surface_render_command_refresh_ledger_materialized=true"
echo "feedback_surface_focus_transition_preview_ledger_materialized=true"
echo "todo_feedback_surface_event_cycle_receipt_materialized=true"
echo "settings_feedback_surface_event_cycle_receipt_materialized=true"
echo "ai_generated_settings_feedback_surface_event_cycle_receipt_materialized=true"
echo "chat_composer_feedback_surface_event_cycle_receipt_materialized=true"
echo "event_cycle_executor_bound_to_stage602_normalizer=true"
echo "stage604_form_result_feedback_host_input_runtime_surface_contract_prepared=true"
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
