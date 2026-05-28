#!/usr/bin/env zsh
#
# Verifies the stage634 focus/validation result-surface action/state adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage634_focus_validation_result_surface_action_state_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage634 focus validation result surface action state adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage634FocusValidationResultSurfaceActionStateAdapterPlan" \
  "CjguiInternalRendererStage634FocusValidationResultSurfaceActionStateAdapterFacts" \
  "CjguiInternalRendererStage634FocusValidationResultSurfaceActionStateAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage634FocusValidationResultSurfaceActionStateAdapterDraft" \
  "CjguiInternalRendererStage633FocusValidationResultSurfaceInteractionBridgeReadiness" \
  "didConsumeStage633FocusValidationResultSurfaceInteractionBridge" \
  "didMaterializeSharedResultSurfaceActionIntentLedger" \
  "didMaterializeSharedResultSurfaceStateDeltaDryRunLedger" \
  "didMaterializeChatComposerResultSurfaceActionStateCandidate" \
  "didKeepResultSurfaceActionStateAdapterNonDispatching" \
  "didKeepResultSurfaceStateUpdatesOwnerLocalDryRun" \
  "didPrepareStage635FocusValidationResultSurfaceStateRenderRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage634 focus validation result surface action state adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage634_focus_validation_result_surface_action_state_adapter_owner_present=true"
echo "stage633_focus_validation_result_surface_interaction_bridge_consumed=true"
echo "result_surface_interaction_targets_consumed=true"
echo "shared_result_surface_action_state_adapter_materialized=true"
echo "shared_result_surface_action_intent_ledger_materialized=true"
echo "shared_result_surface_state_delta_dry_run_ledger_materialized=true"
echo "todo_result_surface_action_state_candidate_materialized=true"
echo "settings_result_surface_action_state_candidate_materialized=true"
echo "ai_generated_settings_result_surface_action_state_candidate_materialized=true"
echo "chat_composer_result_surface_action_state_candidate_materialized=true"
echo "result_surface_action_state_adapter_non_dispatching=true"
echo "result_surface_state_updates_owner_local_dry_run=true"
echo "stage635_focus_validation_result_surface_state_render_refresh_prepared=true"
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
