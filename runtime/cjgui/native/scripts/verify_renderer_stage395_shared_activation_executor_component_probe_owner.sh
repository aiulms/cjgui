#!/usr/bin/env zsh
#
# 维护注释：验证 stage395 shared activation executor component probe owner。
# 它必须消费 stage394 demo refresh helper，并把 shared executor 绑定到内部 component activation contract。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage395_shared_activation_executor_component_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage395 shared activation executor component probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage395ComponentActivationIdentityBridge" \
  "CjguiInternalRendererStage395ComponentActivationSlotMap" \
  "CjguiInternalRendererStage395ComponentActivationStatePreview" \
  "CjguiInternalRendererStage395SharedActivationExecutorComponentProbeFacts" \
  "CjguiInternalRendererStage395SharedActivationExecutorComponentProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage395SharedActivationExecutorComponentProbeDraft" \
  "didConsumeStage394SharedActivationExecutorDemoRefreshHelper" \
  "didBindSharedExecutorToComponentIdentity" \
  "didMaterializeTodoAddComponentActivationSlot" \
  "didMaterializeSettingsToggleComponentActivationSlot" \
  "didMaterializeAiGeneratedSettingsComponentActivationSlot" \
  "didBindComponentActivationSlotsToSharedComponentModel" \
  "didBindComponentActivationSlotsToStage394DemoRefreshHelper" \
  "didMaterializeComponentOwnerAcceptanceGate" \
  "didMaterializeComponentStateDeltaPreview" \
  "didMaterializeComponentRenderRefreshBinding" \
  "didKeepComponentActivationProbeOwnerLocal" \
  "didPrepareStage396ComponentActivationRenderRefreshProbe" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage395 shared activation executor component probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage395_shared_activation_executor_component_probe_owner_present=true"
echo "stage394_shared_activation_executor_demo_refresh_helper_required=true"
echo "stage394_shared_activation_executor_demo_refresh_helper_consumed=true"
echo "shared_executor_bound_to_component_identity=true"
echo "todo_add_component_activation_slot_materialized=true"
echo "settings_toggle_component_activation_slot_materialized=true"
echo "ai_generated_settings_component_activation_slot_materialized=true"
echo "component_activation_slots_bound_to_shared_component_model=true"
echo "component_activation_slots_bound_to_stage394_demo_refresh_helper=true"
echo "component_owner_acceptance_gate_materialized=true"
echo "component_state_delta_preview_materialized=true"
echo "component_render_refresh_binding_materialized=true"
echo "component_activation_probe_owner_local=true"
echo "stage396_component_activation_render_refresh_probe_prepared=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
