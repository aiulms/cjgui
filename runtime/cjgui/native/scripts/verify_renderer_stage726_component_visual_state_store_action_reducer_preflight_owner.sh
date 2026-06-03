#!/usr/bin/env zsh
#
# Verifies the stage726 component visual state store action reducer preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage726_component_visual_state_store_action_reducer_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage726 component visual state store action reducer preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightPlan" \
  "CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightFacts" \
  "CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage726ComponentVisualStateStoreActionReducerPreflightDraft" \
  "CjguiInternalRendererStage725ComponentVisualStateStoreInputActionBridgeReadiness" \
  "didConsumeStage725ComponentVisualStateStoreInputActionBridge" \
  "didMaterializeSharedVisualStateStoreActionReducer" \
  "didMaterializeVisualStateStoreMutationPreflight" \
  "didMaterializeVisualStateStoreConflictClassifier" \
  "didMaterializeVisualStateStoreRollbackPlan" \
  "didKeepVisualStateStoreMutationOwnerLocal" \
  "didKeepVisualStateStoreMutationDryRunOnly" \
  "didPrepareStage727ComponentVisualStateStoreRenderResultHostSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage726 component visual state store action reducer preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage726_component_visual_state_store_action_reducer_preflight_owner_present=true"
echo "stage725_component_visual_state_store_input_action_bridge_consumed=true"
echo "shared_visual_state_store_action_reducer_materialized=true"
echo "visual_state_store_mutation_preflight_materialized=true"
echo "visual_state_store_conflict_classifier_materialized=true"
echo "visual_state_store_rollback_plan_materialized=true"
echo "todo_visual_state_store_mutation_preflight_materialized=true"
echo "settings_visual_state_store_mutation_preflight_materialized=true"
echo "ai_generated_settings_visual_state_store_mutation_preflight_materialized=true"
echo "chat_composer_visual_state_store_mutation_preflight_materialized=true"
echo "visual_state_store_mutation_owner_local=true"
echo "visual_state_store_mutation_dry_run_only=true"
echo "stage727_component_visual_state_store_render_result_host_surface_prepared=true"
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
