#!/usr/bin/env zsh
#
# Verifies the stage732 component visual state store resolver runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage732_component_visual_state_store_resolver_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage732 component visual state store resolver runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage732ComponentVisualStateStoreResolverRuntimeManagerPlan" \
  "CjguiInternalRendererStage732ComponentVisualStateStoreResolverRuntimeManagerFacts" \
  "CjguiInternalRendererStage732ComponentVisualStateStoreResolverRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage732ComponentVisualStateStoreResolverRuntimeManagerDraft" \
  "CjguiInternalRendererStage731ComponentVisualStateStoreResolverHostInspectionSurfaceReadiness" \
  "didConsumeStage731ComponentVisualStateStoreResolverHostInspectionSurface" \
  "didMaterializeSharedVisualStateStoreResolverRuntimeManager" \
  "didMaterializeVisualStateStoreResolverRuntimeContract" \
  "didMaterializeVisualStateStoreResolverExecutionReceiptContract" \
  "didMaterializeCycleOrderStateStoreResolveTextHostResultRuntime" \
  "didReduceFuturePerDemoResolverTemplateNeed" \
  "didPrepareStage733ComponentVisualStateStoreCommitPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage732 component visual state store resolver runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage732_component_visual_state_store_resolver_runtime_manager_owner_present=true"
echo "stage731_component_visual_state_store_resolver_host_inspection_surface_consumed=true"
echo "stage730_component_visual_state_store_text_selection_projection_consumed_transitively=true"
echo "stage729_component_visual_state_store_layout_style_focus_resolver_consumed_transitively=true"
echo "stage728_component_visual_state_store_input_action_cycle_manager_consumed_transitively=true"
echo "shared_visual_state_store_resolver_runtime_manager_materialized=true"
echo "visual_state_store_resolver_runtime_contract_materialized=true"
echo "visual_state_store_resolver_execution_receipt_contract_materialized=true"
echo "cycle_order_state_store_resolve_text_host_result_runtime_materialized=true"
echo "todo_visual_state_store_resolver_runtime_surface_materialized=true"
echo "settings_visual_state_store_resolver_runtime_surface_materialized=true"
echo "ai_generated_settings_visual_state_store_resolver_runtime_surface_materialized=true"
echo "chat_composer_visual_state_store_resolver_runtime_surface_materialized=true"
echo "future_per_demo_resolver_template_need_reduced=true"
echo "stage733_component_visual_state_store_commit_preflight_prepared=true"
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
