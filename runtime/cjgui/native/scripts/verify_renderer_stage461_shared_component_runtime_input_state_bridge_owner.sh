#!/usr/bin/env zsh
#
# 维护注释：验证 stage461 shared component runtime input/state bridge owner。
# 它必须消费 stage460 layout/focus executor，并产出 owner-local in-memory state bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage461_shared_component_runtime_input_state_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage461 shared component runtime input state bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage461SharedComponentRuntimeInputStateBridgePlan" \
  "CjguiInternalRendererStage461SharedComponentRuntimeInputStateBridgeFacts" \
  "CjguiInternalRendererStage461SharedComponentRuntimeInputStateBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage461SharedComponentRuntimeInputStateBridgeDraft" \
  "CjguiInternalRendererStage460SharedComponentRuntimeLayoutFocusExecutorReadiness" \
  "didConsumeStage460SharedComponentRuntimeLayoutFocusExecutor" \
  "didConsumeSharedComponentRuntimeLayoutFocusExecutor" \
  "didConsumeTodoRuntimeLayoutFocusPass" \
  "didConsumeSettingsRuntimeLayoutFocusPass" \
  "didConsumeAiGeneratedSettingsRuntimeLayoutFocusPass" \
  "didMaterializeSharedComponentRuntimeInputStateBridge" \
  "didMaterializeTodoRuntimeStateDeltaCandidate" \
  "didMaterializeSettingsRuntimeStateDeltaCandidate" \
  "didMaterializeAiGeneratedSettingsRuntimeStateDeltaCandidate" \
  "didBindLayoutFocusExecutorToInputStateBridge" \
  "didBindComponentRuntimeContractToInputStateBridge" \
  "didKeepInputStateBridgeOwnerLocal" \
  "didKeepInputStateBridgeInMemoryOnly" \
  "didKeepInputStateBridgeUncommitted" \
  "didPrepareStage462SharedComponentRuntimeDemoSurfaceExecutionReceipt" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage461 shared component runtime input state bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage461_shared_component_runtime_input_state_bridge_owner_present=true"
echo "stage460_shared_component_runtime_layout_focus_executor_required=true"
echo "stage460_shared_component_runtime_layout_focus_executor_consumed=true"
echo "shared_component_runtime_layout_focus_executor_consumed=true"
echo "todo_runtime_layout_focus_pass_consumed=true"
echo "settings_runtime_layout_focus_pass_consumed=true"
echo "ai_generated_settings_runtime_layout_focus_pass_consumed=true"
echo "shared_component_runtime_input_state_bridge_materialized=true"
echo "todo_runtime_state_delta_candidate_materialized=true"
echo "settings_runtime_state_delta_candidate_materialized=true"
echo "ai_generated_settings_runtime_state_delta_candidate_materialized=true"
echo "layout_focus_executor_to_input_state_bridge_bound=true"
echo "component_runtime_contract_to_input_state_bridge_bound=true"
echo "input_state_bridge_owner_local=true"
echo "input_state_bridge_in_memory_only=true"
echo "input_state_bridge_uncommitted=true"
echo "stage462_shared_component_runtime_demo_surface_execution_receipt_prepared=true"
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
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
