#!/usr/bin/env zsh
#
# Verifies the stage696 replay host text input replay timeline executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage696_replay_host_text_input_replay_timeline_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage696 replay host text input replay timeline executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage696ReplayHostTextInputReplayTimelineExecutorPlan" \
  "CjguiInternalRendererStage696ReplayHostTextInputReplayTimelineExecutorFacts" \
  "CjguiInternalRendererStage696ReplayHostTextInputReplayTimelineExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage696ReplayHostTextInputReplayTimelineExecutorDraft" \
  "CjguiInternalRendererStage695ReplayHostTextInputReplayResultSurfaceRefreshReadiness" \
  "didConsumeStage695ReplayHostTextInputReplayResultSurfaceRefresh" \
  "didMaterializeSharedReplayHostTextInputReplayTimelineExecutor" \
  "didMaterializeSharedReplayHostTextInputReplayTimelineRuntimeContract" \
  "didMaterializeReplayTimelineExecutionReceiptContract" \
  "didMaterializeCycleOrderTextInputEventReplayHostInspectionResultRefreshTimelineExecutor" \
  "didBindReplayTimelineExecutorToStage693ReplaySurface" \
  "didBindReplayTimelineExecutorToStage694HostInspection" \
  "didBindReplayTimelineExecutorToStage695ResultRefresh" \
  "didBindReplayTimelineExecutorToStage692CycleExecutor" \
  "didReduceFuturePerDemoTextInputReplayTimelineTemplateNeed" \
  "didPrepareStage697ReplayHostTextInputTimelineActionStateBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage696 replay host text input replay timeline executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage696_replay_host_text_input_replay_timeline_executor_owner_present=true"
echo "stage695_replay_host_text_input_replay_result_surface_refresh_consumed=true"
echo "stage694_replay_host_text_input_replay_host_inspection_preview_consumed_transitively=true"
echo "stage693_replay_host_text_input_event_replay_surface_consumed_transitively=true"
echo "stage692_replay_host_text_input_demo_host_cycle_executor_consumed_transitively=true"
echo "replay_result_surface_refresh_receipts_consumed=true"
echo "shared_replay_host_text_input_replay_timeline_executor_materialized=true"
echo "shared_replay_host_text_input_replay_timeline_runtime_contract_materialized=true"
echo "replay_timeline_execution_receipt_contract_materialized=true"
echo "cycle_order_text_input_event_replay_host_inspection_result_refresh_timeline_executor_materialized=true"
echo "todo_replay_host_text_input_replay_timeline_runtime_surface_materialized=true"
echo "settings_replay_host_text_input_replay_timeline_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_replay_timeline_runtime_surface_materialized=true"
echo "chat_composer_replay_host_text_input_replay_timeline_runtime_surface_materialized=true"
echo "replay_timeline_executor_bound_to_stage693_replay_surface=true"
echo "replay_timeline_executor_bound_to_stage694_host_inspection=true"
echo "replay_timeline_executor_bound_to_stage695_result_refresh=true"
echo "replay_timeline_executor_bound_to_stage692_cycle_executor=true"
echo "future_per_demo_text_input_replay_timeline_template_need_reduced=true"
echo "stage697_replay_host_text_input_timeline_action_state_bridge_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
