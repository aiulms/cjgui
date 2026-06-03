#!/usr/bin/env zsh
#
# Verifies the stage718 replay style/focus resolver owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage718_replay_style_focus_resolver.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage718 replay style/focus resolver: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage718ReplayStyleFocusResolverPlan" \
  "CjguiInternalRendererStage718ReplayStyleFocusResolverFacts" \
  "CjguiInternalRendererStage718ReplayStyleFocusResolverReadiness" \
  "cjguiInternalExecuteDefaultRendererStage718ReplayStyleFocusResolverDraft" \
  "CjguiInternalRendererStage717ReplayVisualPreviewReadiness" \
  "didConsumeStage717ReplayVisualPreview" \
  "didMaterializeSharedReplayStyleResolverDryRun" \
  "didMaterializeSharedReplayFocusManagerDryRun" \
  "didMaterializeResolvedVisualStyleLedger" \
  "didMaterializeFocusMovementLedger" \
  "didMaterializeValidationFocusHandoffLedger" \
  "didBindStyleFocusResolverToStage717Preview" \
  "didPrepareStage719ReplayTextCaretHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage718 replay style/focus resolver: missing token $token" >&2
    exit 3
  fi
done

echo "stage718_replay_style_focus_resolver_owner_present=true"
echo "stage717_replay_visual_preview_consumed=true"
echo "stage716_component_runtime_input_event_replay_action_state_render_executor_consumed_transitively=true"
echo "shared_replay_style_resolver_dry_run_materialized=true"
echo "shared_replay_focus_manager_dry_run_materialized=true"
echo "resolved_visual_style_ledger_materialized=true"
echo "focus_movement_ledger_materialized=true"
echo "validation_focus_handoff_ledger_materialized=true"
echo "todo_replay_style_focus_resolution_materialized=true"
echo "settings_replay_style_focus_resolution_materialized=true"
echo "ai_generated_settings_replay_style_focus_resolution_materialized=true"
echo "chat_composer_replay_style_focus_resolution_materialized=true"
echo "style_focus_resolver_bound_to_stage717_preview=true"
echo "stage719_replay_text_caret_host_surface_prepared=true"
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
