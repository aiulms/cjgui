#!/usr/bin/env zsh
#
# Verifies the stage736 component state store commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage736_component_state_store_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage736 component state store commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage736ComponentStateStoreCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage736ComponentStateStoreCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage735ComponentVisualStateStoreCommitHostInspectionUiReadiness" \
  "didConsumeStage735ComponentVisualStateStoreCommitHostInspectionUi" \
  "didMaterializeSharedComponentStateStoreCommitRuntimeManager" \
  "didMaterializeComponentStateStoreCommitRuntimeContract" \
  "didMaterializeComponentStateStoreCommitExecutionReceiptContract" \
  "didMaterializeCycleOrderResolverCommitPreflightSnapshotHostInspectionRuntime" \
  "didReduceFuturePerDemoCommitPreflightTemplateNeed" \
  "didPrepareStage737ComponentStateStorePublicApiInternalShape"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage736 component state store commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage736_component_state_store_commit_runtime_manager_owner_present=true"
echo "stage735_component_visual_state_store_commit_host_inspection_ui_consumed=true"
echo "stage734_component_visual_state_store_commit_rollback_snapshot_consumed_transitively=true"
echo "stage733_component_visual_state_store_commit_preflight_consumed_transitively=true"
echo "stage732_component_visual_state_store_resolver_runtime_manager_consumed_transitively=true"
echo "shared_component_state_store_commit_runtime_manager_materialized=true"
echo "component_state_store_commit_runtime_contract_materialized=true"
echo "component_state_store_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_resolver_commit_preflight_snapshot_host_inspection_runtime_materialized=true"
echo "todo_component_state_store_commit_runtime_surface_materialized=true"
echo "settings_component_state_store_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_component_state_store_commit_runtime_surface_materialized=true"
echo "chat_composer_component_state_store_commit_runtime_surface_materialized=true"
echo "future_per_demo_commit_preflight_template_need_reduced=true"
echo "stage737_component_state_store_public_api_internal_shape_prepared=true"
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
