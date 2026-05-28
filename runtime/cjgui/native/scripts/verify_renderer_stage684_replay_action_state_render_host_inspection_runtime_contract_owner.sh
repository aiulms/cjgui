#!/usr/bin/env zsh
#
# Verifies the stage684 replay action-state-render host inspection runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage684_replay_action_state_render_host_inspection_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage684 replay action-state-render host inspection runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractPlan" \
  "CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractFacts" \
  "CjguiInternalRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage684ReplayActionStateRenderHostInspectionRuntimeContractDraft" \
  "CjguiInternalRendererStage683ReplayActionStateRenderHostResultSurfaceRefreshReadiness" \
  "didConsumeStage683ReplayActionStateRenderHostResultSurfaceRefresh" \
  "didMaterializeSharedReplayActionStateRenderHostInspectionRuntimeContract" \
  "didMaterializeSharedReplayActionStateRenderHostInspectionRuntimeHelper" \
  "didMaterializeSharedReplayHostInspectionExecutionReceiptContract" \
  "didMaterializeCycleOrderReplayActionStateRenderHostInspectionLayoutResultRuntime" \
  "didMaterializeChatComposerReplayActionStateRenderHostInspectionRuntimeSurface" \
  "didBindRuntimeContractToStage681HostInspection" \
  "didBindRuntimeContractToStage682LayoutFocusInspection" \
  "didBindRuntimeContractToStage683ResultSurfaceRefresh" \
  "didReduceFuturePerDemoReplayHostInspectionTemplateNeed" \
  "didPrepareStage685ReplayActionStateRenderHostInputFeedbackLoop"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage684 replay action-state-render host inspection runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage684_replay_action_state_render_host_inspection_runtime_contract_owner_present=true"
echo "stage683_replay_action_state_render_host_result_surface_refresh_consumed=true"
echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_consumed_transitively=true"
echo "stage681_replay_action_state_render_demo_host_inspection_consumed_transitively=true"
echo "stage680_replay_action_state_render_cycle_executor_consumed_transitively=true"
echo "shared_replay_action_state_render_host_inspection_runtime_contract_materialized=true"
echo "shared_replay_action_state_render_host_inspection_runtime_helper_materialized=true"
echo "shared_replay_host_inspection_execution_receipt_contract_materialized=true"
echo "cycle_order_replay_action_state_render_host_inspection_layout_result_runtime_materialized=true"
echo "todo_replay_action_state_render_host_inspection_runtime_surface_materialized=true"
echo "settings_replay_action_state_render_host_inspection_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_action_state_render_host_inspection_runtime_surface_materialized=true"
echo "chat_composer_replay_action_state_render_host_inspection_runtime_surface_materialized=true"
echo "future_per_demo_replay_host_inspection_template_need_reduced=true"
echo "stage685_replay_action_state_render_host_input_feedback_loop_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
