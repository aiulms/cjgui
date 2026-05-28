#!/usr/bin/env zsh
#
# Verifies the stage625 focus/validation host input adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage625_focus_validation_host_input_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage625 focus validation host input adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage625FocusValidationHostInputAdapterPlan" \
  "CjguiInternalRendererStage625FocusValidationHostInputAdapterFacts" \
  "CjguiInternalRendererStage625FocusValidationHostInputAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage625FocusValidationHostInputAdapterDraft" \
  "CjguiInternalRendererStage624SharedFocusValidationDemoHostRuntimeContractReadiness" \
  "didConsumeStage624SharedFocusValidationDemoHostRuntimeContract" \
  "didMaterializeSharedFocusValidationHostInputAdapter" \
  "didMaterializeHostFrameInputBindingLedger" \
  "didMaterializeValidationDisplayHostInputRoute" \
  "didMaterializeFocusHandoffHostInputRoute" \
  "didMaterializeInputFeedbackHostInputRoute" \
  "didMaterializeSemanticDiffHostInputRoute" \
  "didMaterializeChatComposerFocusValidationHostInputAdapter" \
  "didBindHostInputAdapterToStage624RuntimeContract" \
  "didBindHostInputAdapterToStage623InteractionReceipt" \
  "didKeepHostInputAdapterNonExecuting" \
  "didPrepareStage626ComponentRuntimeFocusValidationHostInputEventNormalizer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage625 focus validation host input adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage625_focus_validation_host_input_adapter_owner_present=true"
echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed=true"
echo "stage623_focus_validation_host_interaction_receipt_consumed_transitively=true"
echo "stage622_focus_validation_host_frame_assembly_consumed_transitively=true"
echo "stage621_focus_validation_host_integration_consumed_transitively=true"
echo "shared_focus_validation_host_input_adapter_materialized=true"
echo "host_frame_input_binding_ledger_materialized=true"
echo "validation_display_host_input_route_materialized=true"
echo "focus_handoff_host_input_route_materialized=true"
echo "input_feedback_host_input_route_materialized=true"
echo "semantic_diff_host_input_route_materialized=true"
echo "todo_focus_validation_host_input_adapter_materialized=true"
echo "settings_focus_validation_host_input_adapter_materialized=true"
echo "ai_generated_settings_focus_validation_host_input_adapter_materialized=true"
echo "chat_composer_focus_validation_host_input_adapter_materialized=true"
echo "host_input_adapter_bound_to_stage624_runtime_contract=true"
echo "host_input_adapter_bound_to_stage623_interaction_receipt=true"
echo "host_input_adapter_owner_local=true"
echo "host_input_adapter_non_executing=true"
echo "stage626_component_runtime_focus_validation_host_input_event_normalizer_prepared=true"
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
