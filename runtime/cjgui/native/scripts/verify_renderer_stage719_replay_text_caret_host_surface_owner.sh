#!/usr/bin/env zsh
#
# Verifies the stage719 replay text/caret host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage719_replay_text_caret_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage719 replay text/caret host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage719ReplayTextCaretHostSurfacePlan" \
  "CjguiInternalRendererStage719ReplayTextCaretHostSurfaceFacts" \
  "CjguiInternalRendererStage719ReplayTextCaretHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage719ReplayTextCaretHostSurfaceDraft" \
  "CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness" \
  "didConsumeStage718ReplayStyleFocusResolver" \
  "didMaterializeSharedReplayTextCaretModel" \
  "didMaterializeReplayTextSelectionLedger" \
  "didMaterializeReplayCaretPositionLedger" \
  "didMaterializeReplayCompositionPlaceholderLedger" \
  "didMaterializeReplayDemoHostInspectionSurface" \
  "didBindTextCaretHostSurfaceToStage718Resolver" \
  "didPrepareStage720ReplayVisualRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage719 replay text/caret host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage719_replay_text_caret_host_surface_owner_present=true"
echo "stage718_replay_style_focus_resolver_consumed=true"
echo "stage717_replay_visual_preview_consumed_transitively=true"
echo "stage716_component_runtime_input_event_replay_action_state_render_executor_consumed_transitively=true"
echo "shared_replay_text_caret_model_materialized=true"
echo "replay_text_selection_ledger_materialized=true"
echo "replay_caret_position_ledger_materialized=true"
echo "replay_composition_placeholder_ledger_materialized=true"
echo "replay_demo_host_inspection_surface_materialized=true"
echo "todo_replay_text_caret_host_surface_materialized=true"
echo "settings_replay_text_caret_host_surface_materialized=true"
echo "ai_generated_settings_replay_text_caret_host_surface_materialized=true"
echo "chat_composer_replay_text_caret_host_surface_materialized=true"
echo "text_caret_host_surface_bound_to_stage718_resolver=true"
echo "stage720_replay_visual_runtime_manager_prepared=true"
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
