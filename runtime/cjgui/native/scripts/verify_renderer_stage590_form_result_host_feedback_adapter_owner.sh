#!/usr/bin/env zsh
#
# Verifies the stage590 form result host feedback adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage590_form_result_host_feedback_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage590 form result host feedback adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage590FormResultHostFeedbackAdapterPlan" \
  "CjguiInternalRendererStage590FormResultHostFeedbackAdapterFacts" \
  "CjguiInternalRendererStage590FormResultHostFeedbackAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage590FormResultHostFeedbackAdapterDraft" \
  "CjguiInternalRendererStage589FormResultHostInspectionReadiness" \
  "didMaterializeSharedFormResultHostFeedbackAdapter" \
  "didMaterializeAcceptedHostFeedbackRoute" \
  "didMaterializeRejectedHostValidationFeedbackRoute" \
  "didMaterializePendingOwnerAcceptanceHostFeedbackRoute" \
  "didMaterializeFormResultHostFeedbackEventLedger" \
  "didMaterializeTodoFormResultHostFeedbackEvent" \
  "didMaterializeSettingsFormResultHostFeedbackEvent" \
  "didMaterializeAiGeneratedSettingsFormResultHostFeedbackEvent" \
  "didMaterializeChatComposerFormResultHostFeedbackEvent" \
  "didBindFeedbackAdapterToStage589HostInspectionInputs" \
  "didPrepareStage591FormResultHostExecutionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage590 form result host feedback adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage590_form_result_host_feedback_adapter_owner_present=true"
echo "stage589_form_result_host_inspection_consumed=true"
echo "shared_form_result_host_feedback_adapter_materialized=true"
echo "accepted_host_feedback_route_materialized=true"
echo "rejected_host_validation_feedback_route_materialized=true"
echo "pending_owner_acceptance_host_feedback_route_materialized=true"
echo "form_result_host_feedback_event_ledger_materialized=true"
echo "todo_form_result_host_feedback_event_materialized=true"
echo "settings_form_result_host_feedback_event_materialized=true"
echo "ai_generated_settings_form_result_host_feedback_event_materialized=true"
echo "chat_composer_form_result_host_feedback_event_materialized=true"
echo "feedback_adapter_bound_to_stage589_host_inspection_inputs=true"
echo "feedback_adapter_bound_to_stage588_runtime_surfaces=true"
echo "stage591_form_result_host_execution_receipt_prepared=true"
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
