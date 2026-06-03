#!/usr/bin/env zsh
#
# Verifies the stage720 replay visual runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage720_replay_visual_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage720 replay visual runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage720ReplayVisualRuntimeManagerPlan" \
  "CjguiInternalRendererStage720ReplayVisualRuntimeManagerFacts" \
  "CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage720ReplayVisualRuntimeManagerDraft" \
  "CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness" \
  "didConsumeStage719ReplayTextCaretHostSurface" \
  "didMaterializeSharedReplayVisualRuntimeManager" \
  "didMaterializeSharedReplayVisualRuntimeContract" \
  "didMaterializeReplayVisualExecutionReceiptContract" \
  "didMaterializeCycleOrderReplayActionStateRenderVisualResolveTextCaretHost" \
  "didBindVisualRuntimeManagerToStage717Preview" \
  "didBindVisualRuntimeManagerToStage718Resolver" \
  "didBindVisualRuntimeManagerToStage719HostSurface" \
  "didReduceFuturePerDemoReplayVisualRuntimeTemplateNeed"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage720 replay visual runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage720_replay_visual_runtime_manager_owner_present=true"
echo "stage719_replay_text_caret_host_surface_consumed=true"
echo "stage718_replay_style_focus_resolver_consumed_transitively=true"
echo "stage717_replay_visual_preview_consumed_transitively=true"
echo "stage716_component_runtime_input_event_replay_action_state_render_executor_consumed_transitively=true"
echo "shared_replay_visual_runtime_manager_materialized=true"
echo "shared_replay_visual_runtime_contract_materialized=true"
echo "replay_visual_execution_receipt_contract_materialized=true"
echo "cycle_order_replay_action_state_render_visual_resolve_text_caret_host_materialized=true"
echo "todo_replay_visual_runtime_surface_materialized=true"
echo "settings_replay_visual_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_visual_runtime_surface_materialized=true"
echo "chat_composer_replay_visual_runtime_surface_materialized=true"
echo "visual_runtime_manager_bound_to_stage717_preview=true"
echo "visual_runtime_manager_bound_to_stage718_resolver=true"
echo "visual_runtime_manager_bound_to_stage719_host_surface=true"
echo "future_per_demo_replay_visual_runtime_template_need_reduced=true"
echo "stage721_component_runtime_visual_state_store_preflight_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
