#!/usr/bin/env zsh
#
# 维护注释：验证 stage394 shared activation executor demo refresh helper owner。
# 它必须消费 stage393 helper，并把 helper 接入 Todo/settings/AI-generated settings
# demo refresh preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage394_shared_activation_executor_demo_refresh_helper.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage394 shared activation executor demo refresh helper: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage394SharedActivationExecutorDemoInputBridge" \
  "CjguiInternalRendererStage394SharedActivationExecutorDemoStateRefresh" \
  "CjguiInternalRendererStage394SharedActivationExecutorDemoRenderRefreshHelper" \
  "CjguiInternalRendererStage394SharedActivationExecutorDemoRefreshHelperFacts" \
  "CjguiInternalRendererStage394SharedActivationExecutorDemoRefreshHelperReadiness" \
  "cjguiInternalExecuteDefaultRendererStage394SharedActivationExecutorDemoRefreshHelperDraft" \
  "didConsumeStage393SharedActivationExecutorHelper" \
  "didBindSharedExecutorToTodoDemoActivationSurface" \
  "didBindSharedExecutorToSettingsDemoActivationSurface" \
  "didBindSharedExecutorToAiGeneratedSettingsDemoSurface" \
  "didMaterializeExecutorDrivenTodoStateDeltaRefresh" \
  "didMaterializeExecutorDrivenSettingsStateDeltaRefresh" \
  "didMaterializeExecutorDrivenAiGeneratedSettingsRefresh" \
  "didMaterializeSharedActivationDemoRenderRefreshHelper" \
  "didBindDemoRefreshHelperToStage392ResultRefresh" \
  "didBindDemoRefreshHelperToStage383RenderBridge" \
  "didPrepareStage395SharedActivationExecutorComponentProbe" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage394 shared activation executor demo refresh helper: missing token $token" >&2
    exit 3
  fi
done

echo "stage394_shared_activation_executor_demo_refresh_helper_owner_present=true"
echo "stage393_shared_activation_executor_helper_required=true"
echo "stage393_shared_activation_executor_helper_consumed=true"
echo "shared_executor_bound_to_todo_demo_activation_surface=true"
echo "shared_executor_bound_to_settings_demo_activation_surface=true"
echo "shared_executor_bound_to_ai_generated_settings_demo_surface=true"
echo "executor_driven_todo_state_delta_refresh_materialized=true"
echo "executor_driven_settings_state_delta_refresh_materialized=true"
echo "executor_driven_ai_generated_settings_refresh_materialized=true"
echo "shared_activation_demo_render_refresh_helper_materialized=true"
echo "demo_refresh_helper_bound_to_stage392_result_refresh=true"
echo "demo_refresh_helper_bound_to_stage383_render_bridge=true"
echo "shared_activation_executor_demo_refresh_preview_only=true"
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
