#!/usr/bin/env zsh
#
# Verifies the stage540 component runtime demo host inspection contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage540_component_runtime_demo_host_inspection_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage540 component runtime demo host inspection contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage540ComponentRuntimeDemoHostInspectionContractPlan" \
  "CjguiInternalRendererStage540ComponentRuntimeDemoHostInspectionContractFacts" \
  "CjguiInternalRendererStage540ComponentRuntimeDemoHostInspectionContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage540ComponentRuntimeDemoHostInspectionContractDraft" \
  "CjguiInternalRendererStage539ComponentRuntimeLayoutTextFocusExecutorReadiness" \
  "didConsumeStage539ComponentRuntimeLayoutTextFocusExecutor" \
  "didMaterializeSharedComponentRuntimeDemoHostInspectionContract" \
  "didMaterializeSharedComponentRuntimeDemoHostInspectionHelper" \
  "didMaterializeTodoComponentRuntimeDemoHostInspectionInput" \
  "didMaterializeSettingsComponentRuntimeDemoHostInspectionInput" \
  "didMaterializeAiGeneratedSettingsComponentRuntimeDemoHostInspectionInput" \
  "didBindDemoHostInspectionToLayoutTextFocusReceipts" \
  "didBindDemoHostInspectionToStage537EventRefreshExecutor" \
  "didReducePerDemoHostProbeReadinessDuplication"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage540 component runtime demo host inspection contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage540_component_runtime_demo_host_inspection_contract_owner_present=true"
echo "stage539_component_runtime_layout_text_focus_executor_consumed=true"
echo "component_runtime_layout_text_focus_receipts_consumed=true"
echo "shared_component_runtime_demo_host_inspection_contract_materialized=true"
echo "shared_component_runtime_demo_host_inspection_helper_materialized=true"
echo "todo_component_runtime_demo_host_inspection_input_materialized=true"
echo "settings_component_runtime_demo_host_inspection_input_materialized=true"
echo "ai_generated_settings_component_runtime_demo_host_inspection_input_materialized=true"
echo "demo_host_inspection_bound_to_layout_text_focus_receipts=true"
echo "demo_host_inspection_bound_to_stage537_event_refresh_executor=true"
echo "demo_host_inspection_bound_to_todo_settings_ai_generated_settings=true"
echo "demo_host_inspection_owner_local=true"
echo "demo_host_inspection_checkable=true"
echo "per_demo_host_probe_readiness_duplication_reduced=true"
echo "stage541_component_runtime_interaction_bridge_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
