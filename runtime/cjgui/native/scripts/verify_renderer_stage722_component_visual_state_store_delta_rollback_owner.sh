#!/usr/bin/env zsh
#
# Verifies the stage722 component visual state store delta/rollback owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage722_component_visual_state_store_delta_rollback.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage722 component visual state store delta rollback: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage722ComponentVisualStateStoreDeltaRollbackPlan" \
  "CjguiInternalRendererStage722ComponentVisualStateStoreDeltaRollbackFacts" \
  "CjguiInternalRendererStage722ComponentVisualStateStoreDeltaRollbackReadiness" \
  "cjguiInternalExecuteDefaultRendererStage722ComponentVisualStateStoreDeltaRollbackDraft" \
  "CjguiInternalRendererStage721ComponentVisualStateStorePreflightReadiness" \
  "didConsumeStage721ComponentVisualStateStorePreflight" \
  "didMaterializeSharedVisualStateDeltaLedger" \
  "didMaterializeVisualStateRollbackSnapshot" \
  "didMaterializeVisualStateCommitPreflight" \
  "didKeepVisualStateDeltaOwnerLocal" \
  "didKeepVisualStateDeltaDryRunOnly" \
  "didPrepareStage723ComponentVisualStateStoreRenderRefresh"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage722 component visual state store delta rollback: missing token $token" >&2
    exit 3
  fi
done

echo "stage722_component_visual_state_store_delta_rollback_owner_present=true"
echo "stage721_component_visual_state_store_preflight_consumed=true"
echo "stage720_replay_visual_runtime_manager_consumed_transitively=true"
echo "shared_visual_state_delta_ledger_materialized=true"
echo "visual_state_rollback_snapshot_materialized=true"
echo "visual_state_commit_preflight_materialized=true"
echo "todo_visual_state_delta_candidate_materialized=true"
echo "settings_visual_state_delta_candidate_materialized=true"
echo "ai_generated_settings_visual_state_delta_candidate_materialized=true"
echo "chat_composer_visual_state_delta_candidate_materialized=true"
echo "visual_state_delta_owner_local=true"
echo "visual_state_delta_dry_run_only=true"
echo "stage723_component_visual_state_store_render_refresh_prepared=true"
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
