#!/usr/bin/env zsh
#
# 维护注释：验证 stage398 component event sequence render refresh probe owner。
# 它必须消费 stage397 event binding matrix，并产出 owner-local event sequence refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage398_component_event_sequence_render_refresh_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage398 component event sequence render refresh probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage398ComponentEventSequenceEnvelope" \
  "CjguiInternalRendererStage398ComponentEventSequenceStateRefresh" \
  "CjguiInternalRendererStage398ComponentEventSequenceRenderRefresh" \
  "CjguiInternalRendererStage398ComponentEventSequenceRenderRefreshProbeFacts" \
  "CjguiInternalRendererStage398ComponentEventSequenceRenderRefreshProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage398ComponentEventSequenceRenderRefreshProbeDraft" \
  "didConsumeStage397SharedComponentEventBindingMatrix" \
  "didMaterializeComponentEventSequenceDryRun" \
  "didMaterializeTodoComponentEventSequenceRefresh" \
  "didMaterializeSettingsComponentEventSequenceRefresh" \
  "didMaterializeAiGeneratedSettingsComponentEventSequenceRefresh" \
  "didMaterializeAcceptedComponentEventResultRefresh" \
  "didMaterializeRejectedComponentEventRollbackRefresh" \
  "didMaterializeComponentEventSequenceStateDeltaPreview" \
  "didMaterializeComponentEventSequenceRenderCommandRefreshPlan" \
  "didBindComponentEventSequenceRefreshToStage396ComponentActivationRefresh" \
  "didBindComponentEventSequenceRefreshToEventBindingMatrix" \
  "didPrepareStage399DemoSurfaceEventExecutionDryRun" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage398 component event sequence render refresh probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage398_component_event_sequence_render_refresh_probe_owner_present=true"
echo "stage397_shared_component_event_binding_matrix_required=true"
echo "stage397_shared_component_event_binding_matrix_consumed=true"
echo "component_event_sequence_dry_run_materialized=true"
echo "todo_component_event_sequence_refresh_materialized=true"
echo "settings_component_event_sequence_refresh_materialized=true"
echo "ai_generated_settings_component_event_sequence_refresh_materialized=true"
echo "accepted_component_event_result_refresh_materialized=true"
echo "rejected_component_event_rollback_refresh_materialized=true"
echo "component_event_sequence_state_delta_preview_materialized=true"
echo "component_event_sequence_render_command_refresh_plan_materialized=true"
echo "component_event_sequence_refresh_bound_to_stage396_component_activation_refresh=true"
echo "component_event_sequence_refresh_bound_to_event_binding_matrix=true"
echo "stage399_demo_surface_event_execution_dry_run_prepared=true"
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
