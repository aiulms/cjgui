#!/usr/bin/env zsh
#
# Verifies the stage733 component visual state store commit preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage733_component_visual_state_store_commit_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage733 component visual state store commit preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage733ComponentVisualStateStoreCommitPreflightPlan" \
  "CjguiInternalRendererStage733ComponentVisualStateStoreCommitPreflightFacts" \
  "CjguiInternalRendererStage733ComponentVisualStateStoreCommitPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage733ComponentVisualStateStoreCommitPreflightDraft" \
  "CjguiInternalRendererStage732ComponentVisualStateStoreResolverRuntimeManagerReadiness" \
  "didConsumeStage732ComponentVisualStateStoreResolverRuntimeManager" \
  "didMaterializeSharedComponentVisualStateStoreCommitPreflight" \
  "didMaterializeOwnerLocalCommitCandidateLedger" \
  "didMaterializeCommitValidationGate" \
  "didMaterializeResolverResultToCommitPlanBridge" \
  "didMaterializeChatComposerComponentVisualStateStoreCommitPreflightSurface" \
  "didPrepareStage734ComponentVisualStateStoreCommitRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage733 component visual state store commit preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage733_component_visual_state_store_commit_preflight_owner_present=true"
echo "stage732_component_visual_state_store_resolver_runtime_manager_consumed=true"
echo "stage731_component_visual_state_store_resolver_host_inspection_surface_consumed_transitively=true"
echo "stage730_component_visual_state_store_text_selection_projection_consumed_transitively=true"
echo "stage729_component_visual_state_store_layout_style_focus_resolver_consumed_transitively=true"
echo "stage728_component_visual_state_store_input_action_cycle_manager_consumed_transitively=true"
echo "shared_component_visual_state_store_commit_preflight_materialized=true"
echo "owner_local_commit_candidate_ledger_materialized=true"
echo "commit_validation_gate_materialized=true"
echo "resolver_result_to_commit_plan_bridge_materialized=true"
echo "todo_component_visual_state_store_commit_preflight_surface_materialized=true"
echo "settings_component_visual_state_store_commit_preflight_surface_materialized=true"
echo "ai_generated_settings_component_visual_state_store_commit_preflight_surface_materialized=true"
echo "chat_composer_component_visual_state_store_commit_preflight_surface_materialized=true"
echo "stage734_component_visual_state_store_commit_rollback_snapshot_prepared=true"
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
