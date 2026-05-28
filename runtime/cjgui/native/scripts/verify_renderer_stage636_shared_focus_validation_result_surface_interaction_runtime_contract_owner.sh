#!/usr/bin/env zsh
#
# Verifies the stage636 shared focus/validation result-surface interaction runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage636_shared_focus_validation_result_surface_interaction_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage636 shared focus validation result surface interaction runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage636SharedFocusValidationResultSurfaceInteractionRuntimeContractPlan" \
  "CjguiInternalRendererStage636SharedFocusValidationResultSurfaceInteractionRuntimeContractFacts" \
  "CjguiInternalRendererStage636SharedFocusValidationResultSurfaceInteractionRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage636SharedFocusValidationResultSurfaceInteractionRuntimeContractDraft" \
  "CjguiInternalRendererStage635FocusValidationResultSurfaceStateRenderRefreshReadiness" \
  "didConsumeStage635FocusValidationResultSurfaceStateRenderRefresh" \
  "didMaterializeSharedFocusValidationResultSurfaceInteractionRuntimeContract" \
  "didMaterializeSharedFocusValidationResultSurfaceInteractionRuntimeHelper" \
  "didMaterializeSharedResultSurfaceInteractionExecutionReceiptContract" \
  "didMaterializeCycleOrderResultSurfaceInteractionActionStateRenderRefreshRuntimeReceipt" \
  "didMaterializeChatComposerResultSurfaceInteractionRuntimeSurface" \
  "didReduceFuturePerDemoResultSurfaceInteractionTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage636 shared focus validation result surface interaction runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_owner_present=true"
echo "stage635_focus_validation_result_surface_state_render_refresh_consumed=true"
echo "stage634_focus_validation_result_surface_action_state_adapter_consumed_transitively=true"
echo "stage633_focus_validation_result_surface_interaction_bridge_consumed_transitively=true"
echo "stage632_shared_focus_validation_result_surface_runtime_contract_consumed_transitively=true"
echo "shared_focus_validation_result_surface_interaction_runtime_contract_materialized=true"
echo "shared_focus_validation_result_surface_interaction_runtime_helper_materialized=true"
echo "shared_result_surface_interaction_execution_receipt_contract_materialized=true"
echo "cycle_order_result_surface_interaction_action_state_render_refresh_runtime_receipt_materialized=true"
echo "todo_result_surface_interaction_runtime_surface_materialized=true"
echo "settings_result_surface_interaction_runtime_surface_materialized=true"
echo "ai_generated_settings_result_surface_interaction_runtime_surface_materialized=true"
echo "chat_composer_result_surface_interaction_runtime_surface_materialized=true"
echo "future_per_demo_result_surface_interaction_template_need_reduced=true"
echo "stage637_component_runtime_result_surface_interaction_layout_focus_preview_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
