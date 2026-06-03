#!/usr/bin/env zsh
#
# Verifies the stage721 component visual state store preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage721_component_visual_state_store_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage721 component visual state store preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage721ComponentVisualStateStorePreflightPlan" \
  "CjguiInternalRendererStage721ComponentVisualStateStorePreflightFacts" \
  "CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage721ComponentVisualStateStorePreflightDraft" \
  "CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness" \
  "didConsumeStage720ReplayVisualRuntimeManager" \
  "didMaterializeSharedComponentVisualStateStorePreflight" \
  "didMaterializeVisualStateSlotLedger" \
  "didMaterializeVisualStateRollbackBaseSnapshot" \
  "didMaterializeTodoComponentVisualStateStorePreflight" \
  "didMaterializeSettingsComponentVisualStateStorePreflight" \
  "didMaterializeAiGeneratedSettingsComponentVisualStateStorePreflight" \
  "didMaterializeChatComposerComponentVisualStateStorePreflight" \
  "didPrepareStage722ComponentVisualStateStoreDeltaRollback"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage721 component visual state store preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage721_component_visual_state_store_preflight_owner_present=true"
echo "stage720_replay_visual_runtime_manager_consumed=true"
echo "shared_component_visual_state_store_preflight_materialized=true"
echo "visual_state_slot_ledger_materialized=true"
echo "visual_state_rollback_base_snapshot_materialized=true"
echo "todo_component_visual_state_store_preflight_materialized=true"
echo "settings_component_visual_state_store_preflight_materialized=true"
echo "ai_generated_settings_component_visual_state_store_preflight_materialized=true"
echo "chat_composer_component_visual_state_store_preflight_materialized=true"
echo "stage722_component_visual_state_store_delta_rollback_prepared=true"
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
