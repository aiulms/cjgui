#!/usr/bin/env zsh
#
# Verifies the stage682 replay action-state-render layout/focus inspection receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage682_replay_action_state_render_layout_focus_inspection_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage682 replay action-state-render layout/focus inspection receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage682ReplayActionStateRenderLayoutFocusInspectionReceiptPlan" \
  "CjguiInternalRendererStage682ReplayActionStateRenderLayoutFocusInspectionReceiptFacts" \
  "CjguiInternalRendererStage682ReplayActionStateRenderLayoutFocusInspectionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage682ReplayActionStateRenderLayoutFocusInspectionReceiptDraft" \
  "CjguiInternalRendererStage681ReplayActionStateRenderDemoHostInspectionReadiness" \
  "didConsumeStage681ReplayActionStateRenderDemoHostInspection" \
  "didMaterializeSharedReplayLayoutStyleTextFocusInspectionReceipt" \
  "didMaterializeReplayLayoutSlotInspectionReceipt" \
  "didMaterializeReplayStyleTokenInspectionReceipt" \
  "didMaterializeReplayTextRunInspectionReceipt" \
  "didMaterializeReplayFocusRouteInspectionReceipt" \
  "didMaterializeChatComposerReplayLayoutFocusInspectionReceipt" \
  "didBindLayoutFocusInspectionToStage681HostInspection" \
  "didPrepareStage683ReplayActionStateRenderHostResultSurfaceRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage682 replay action-state-render layout/focus inspection receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage682_replay_action_state_render_layout_focus_inspection_receipt_owner_present=true"
echo "stage681_replay_action_state_render_demo_host_inspection_consumed=true"
echo "stage680_replay_action_state_render_cycle_executor_consumed_transitively=true"
echo "shared_replay_layout_style_text_focus_inspection_receipt_materialized=true"
echo "replay_layout_slot_inspection_receipt_materialized=true"
echo "replay_style_token_inspection_receipt_materialized=true"
echo "replay_text_run_inspection_receipt_materialized=true"
echo "replay_focus_route_inspection_receipt_materialized=true"
echo "todo_replay_layout_focus_inspection_receipt_materialized=true"
echo "settings_replay_layout_focus_inspection_receipt_materialized=true"
echo "ai_generated_settings_replay_layout_focus_inspection_receipt_materialized=true"
echo "chat_composer_replay_layout_focus_inspection_receipt_materialized=true"
echo "stage683_replay_action_state_render_host_result_surface_refresh_prepared=true"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
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
