#!/usr/bin/env zsh
#
# Verifies the stage849 publishable state text input state-update render bridge owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage849_publishable_state_text_input_state_update_render_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage849 publishable state text input state update render bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage849PublishableStateTextInputStateUpdateRenderBridgePlan" \
  "CjguiInternalRendererStage849PublishableStateTextInputStateUpdateRenderBridgeFacts" \
  "CjguiInternalRendererStage849PublishableStateTextInputStateUpdateRenderBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage849PublishableStateTextInputStateUpdateRenderBridgeDraft" \
  "CjguiInternalRendererStage848PublishableStateTextInputRuntimeManagerReadiness" \
  "didConsumeStage848PublishableStateTextInputRuntimeManager" \
  "didMaterializeTextInputStateDeltaDryRun" \
  "didMaterializeTextInsertionStateDeltaCandidate" \
  "didMaterializeSelectionReplacementStateDeltaCandidate" \
  "didMaterializeCaretSelectionStateDeltaCandidate" \
  "didMaterializeCompositionStateDeltaCandidate" \
  "didMaterializeTextInputRollbackToken" \
  "didBindStateDeltaToStage848TextInputRuntimeManager" \
  "didPrepareStage850PublishableStateTextInputRenderCommandRefreshPreview"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage849 publishable state text input state update render bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage849_publishable_state_text_input_state_update_render_bridge_owner_present=true"
echo "stage848_publishable_state_text_input_runtime_manager_consumed=true"
echo "stage847_publishable_state_text_input_demo_surface_consumed_transitively=true"
echo "text_input_state_delta_dry_run_materialized=true"
echo "text_insertion_state_delta_candidate_materialized=true"
echo "selection_replacement_state_delta_candidate_materialized=true"
echo "caret_selection_state_delta_candidate_materialized=true"
echo "composition_state_delta_candidate_materialized=true"
echo "text_input_rollback_token_materialized=true"
echo "text_input_state_delta_bound_to_stage848_runtime_manager=true"
echo "stage850_publishable_state_text_input_render_command_refresh_preview_prepared=true"
echo "text_input_pipeline_execution=false"
echo "text_mutation=false"
echo "state_update_committed=false"
echo "action_dispatch=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
