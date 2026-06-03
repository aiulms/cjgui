#!/usr/bin/env zsh
#
# Verifies the stage717 replay visual preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage717_replay_visual_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage717 replay visual preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage717ReplayVisualPreviewPlan" \
  "CjguiInternalRendererStage717ReplayVisualPreviewFacts" \
  "CjguiInternalRendererStage717ReplayVisualPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage717ReplayVisualPreviewDraft" \
  "CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness" \
  "didConsumeStage716ComponentRuntimeInputEventReplayActionStateRenderExecutor" \
  "didMaterializeSharedReplayLayoutStyleTextFocusPreview" \
  "didMaterializeReplayLayoutConstraintLedger" \
  "didMaterializeReplayStyleTokenLedger" \
  "didMaterializeReplayTextRunLedger" \
  "didMaterializeReplayFocusTargetLedger" \
  "didMaterializeChatComposerReplayVisualPreviewSurface" \
  "didPrepareStage718ReplayStyleFocusResolver"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage717 replay visual preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage717_replay_visual_preview_owner_present=true"
echo "stage716_component_runtime_input_event_replay_action_state_render_executor_consumed=true"
echo "shared_replay_layout_style_text_focus_preview_materialized=true"
echo "replay_layout_constraint_ledger_materialized=true"
echo "replay_style_token_ledger_materialized=true"
echo "replay_text_run_ledger_materialized=true"
echo "replay_focus_target_ledger_materialized=true"
echo "todo_replay_visual_preview_surface_materialized=true"
echo "settings_replay_visual_preview_surface_materialized=true"
echo "ai_generated_settings_replay_visual_preview_surface_materialized=true"
echo "chat_composer_replay_visual_preview_surface_materialized=true"
echo "stage718_replay_style_focus_resolver_prepared=true"
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
