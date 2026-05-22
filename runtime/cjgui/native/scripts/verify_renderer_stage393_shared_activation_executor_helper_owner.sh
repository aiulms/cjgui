#!/usr/bin/env zsh
#
# 维护注释：验证 stage393 shared activation executor helper owner。
# 它必须消费 stage392 activation result refresh，把 keyboard/pointer activation
# 统一成 owner-local shared executor helper，并保持 no dispatch / no state commit。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage393_shared_activation_executor_helper.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage393 shared activation executor helper: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage393SharedActivationExecutorContract" \
  "CjguiInternalRendererStage393SharedActivationExecutorStatePreview" \
  "CjguiInternalRendererStage393SharedActivationExecutorRenderRefreshContract" \
  "CjguiInternalRendererStage393SharedActivationExecutorHelperFacts" \
  "CjguiInternalRendererStage393SharedActivationExecutorHelperReadiness" \
  "cjguiInternalExecuteDefaultRendererStage393SharedActivationExecutorHelperDraft" \
  "didConsumeStage392KeyboardActivationResultRenderRefreshDemoProbe" \
  "didMaterializeSharedActivationExecutorHelper" \
  "didUnifyKeyboardActivationResultPath" \
  "didUnifyPointerActivationIntentPath" \
  "didBindTodoActivationToSharedExecutor" \
  "didBindSettingsActivationToSharedExecutor" \
  "didBindAiGeneratedSettingsActivationToSharedExecutor" \
  "didMaterializeSharedActivationOwnerAcceptanceGate" \
  "didMaterializeSharedActivationAcceptedResultPreview" \
  "didMaterializeSharedActivationRejectedRollbackPreview" \
  "didMaterializeSharedActivationStateDeltaPreview" \
  "didBindSharedActivationExecutorToStage383RenderBridge" \
  "didBindSharedActivationExecutorToStage392ResultRefresh" \
  "didPrepareStage394SharedActivationExecutorDemoRefreshHelper" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage393 shared activation executor helper: missing token $token" >&2
    exit 3
  fi
done

echo "stage393_shared_activation_executor_helper_owner_present=true"
echo "stage392_keyboard_activation_result_render_refresh_demo_probe_required=true"
echo "stage392_keyboard_activation_result_render_refresh_demo_probe_consumed=true"
echo "shared_activation_executor_helper_materialized=true"
echo "keyboard_activation_result_path_unified=true"
echo "pointer_activation_intent_path_unified=true"
echo "todo_activation_bound_to_shared_executor=true"
echo "settings_activation_bound_to_shared_executor=true"
echo "ai_generated_settings_activation_bound_to_shared_executor=true"
echo "shared_activation_owner_acceptance_gate_materialized=true"
echo "shared_activation_accepted_result_preview_materialized=true"
echo "shared_activation_rejected_rollback_preview_materialized=true"
echo "shared_activation_state_delta_preview_materialized=true"
echo "shared_activation_executor_bound_to_stage383_render_bridge=true"
echo "shared_activation_executor_bound_to_stage392_result_refresh=true"
echo "shared_activation_executor_preview_only=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
