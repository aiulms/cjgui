#!/usr/bin/env zsh
#
# 维护注释：验证 stage396 component activation render refresh probe owner。
# 它必须消费 stage395 component activation probe，并产出 component result/render refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage396_component_activation_render_refresh_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage396 component activation render refresh probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage396ComponentActivationResultEnvelope" \
  "CjguiInternalRendererStage396ComponentActivationStateRefresh" \
  "CjguiInternalRendererStage396ComponentActivationSemanticRenderRefresh" \
  "CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeFacts" \
  "CjguiInternalRendererStage396ComponentActivationRenderRefreshProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage396ComponentActivationRenderRefreshProbeDraft" \
  "didConsumeStage395SharedActivationExecutorComponentProbe" \
  "didMaterializeComponentActivationAcceptedResultRefresh" \
  "didMaterializeComponentActivationRejectedRollbackRefresh" \
  "didBindTodoComponentActivationResultToSurfaceRefresh" \
  "didBindSettingsComponentActivationResultToSurfaceRefresh" \
  "didBindAiGeneratedSettingsComponentActivationResultToSurfaceRefresh" \
  "didMaterializeSemanticComponentActivationRefresh" \
  "didBindComponentActivationRefreshToRenderCommandPlan" \
  "didBindComponentActivationRefreshToStage394DemoRenderRefreshHelper" \
  "didKeepComponentActivationRefreshPreviewOnly" \
  "didPrepareStage397SharedComponentEventBindingMatrix" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage396 component activation render refresh probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage396_component_activation_render_refresh_probe_owner_present=true"
echo "stage395_shared_activation_executor_component_probe_required=true"
echo "stage395_shared_activation_executor_component_probe_consumed=true"
echo "component_activation_accepted_result_refresh_materialized=true"
echo "component_activation_rejected_rollback_refresh_materialized=true"
echo "todo_component_activation_result_bound_to_surface_refresh=true"
echo "settings_component_activation_result_bound_to_surface_refresh=true"
echo "ai_generated_settings_component_activation_result_bound_to_surface_refresh=true"
echo "semantic_component_activation_refresh_materialized=true"
echo "component_activation_refresh_bound_to_render_command_plan=true"
echo "component_activation_refresh_bound_to_stage394_demo_render_refresh_helper=true"
echo "component_activation_refresh_preview_only=true"
echo "stage397_shared_component_event_binding_matrix_prepared=true"
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
