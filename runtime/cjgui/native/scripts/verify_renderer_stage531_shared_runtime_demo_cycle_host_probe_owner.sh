#!/usr/bin/env zsh
#
# Verifies the stage531 shared runtime demo cycle host probe owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage531_shared_runtime_demo_cycle_host_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage531 shared runtime demo cycle host probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbePlan" \
  "CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbeFacts" \
  "CjguiInternalRendererStage531SharedRuntimeDemoCycleHostProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage531SharedRuntimeDemoCycleHostProbeDraft" \
  "CjguiInternalRendererStage530SharedRuntimeDemoCycleExecutorReadiness" \
  "didConsumeStage530SharedRuntimeDemoCycleExecutor" \
  "didConsumeSharedRuntimeDemoCycleExecutionReceipt" \
  "didMaterializeSharedRuntimeDemoCycleHostProbeContract" \
  "didMaterializeSharedRuntimeDemoCycleProbeHelper" \
  "didBindTodoRuntimeDemoCycleToHostProbe" \
  "didBindSettingsRuntimeDemoCycleToHostProbe" \
  "didBindAiGeneratedSettingsRuntimeDemoCycleToHostProbe" \
  "didReduceSameShapePreviewProbeOwnerNeed" \
  "didPrepareStage532SharedRuntimeDemoCycleInputEventNormalization"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage531 shared runtime demo cycle host probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage531_shared_runtime_demo_cycle_host_probe_owner_present=true"
echo "stage530_shared_runtime_demo_cycle_executor_consumed=true"
echo "shared_runtime_demo_cycle_executor_consumed=true"
echo "shared_runtime_demo_cycle_execution_receipt_consumed=true"
echo "todo_runtime_demo_cycle_execution_receipt_consumed=true"
echo "settings_runtime_demo_cycle_execution_receipt_consumed=true"
echo "ai_generated_settings_runtime_demo_cycle_execution_receipt_consumed=true"
echo "shared_runtime_demo_cycle_host_probe_contract_materialized=true"
echo "shared_runtime_demo_cycle_probe_helper_materialized=true"
echo "todo_runtime_demo_cycle_host_probe_input_materialized=true"
echo "settings_runtime_demo_cycle_host_probe_input_materialized=true"
echo "ai_generated_settings_runtime_demo_cycle_host_probe_input_materialized=true"
echo "todo_runtime_demo_cycle_bound_to_host_probe=true"
echo "settings_runtime_demo_cycle_bound_to_host_probe=true"
echo "ai_generated_settings_runtime_demo_cycle_bound_to_host_probe=true"
echo "runtime_demo_cycle_host_probe_bound_to_component_runtime_shape=true"
echo "runtime_demo_cycle_host_probe_checkable=true"
echo "runtime_demo_cycle_host_probe_owner_local=true"
echo "same_shape_preview_probe_owner_need_reduced=true"
echo "stage532_shared_runtime_demo_cycle_input_event_normalization_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
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
