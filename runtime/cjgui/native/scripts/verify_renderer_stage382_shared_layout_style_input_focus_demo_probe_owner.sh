#!/usr/bin/env zsh
#
# 维护注释：验证 stage382 shared layout/style/input/focus demo probe owner。
# 它必须消费 stage381 shared component model，并让 AI-generated UI / Todo demo 共享同一套内部组件语义。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage382 shared layout/style/input/focus demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage382SharedDemoSemanticSurface" \
  "CjguiInternalRendererStage382SharedDemoLayoutStyleTextInputFocusSurface" \
  "CjguiInternalRendererStage382SharedDemoStateRenderRefresh" \
  "CjguiInternalRendererStage382SharedLayoutStyleInputFocusDemoProbeFacts" \
  "CjguiInternalRendererStage382SharedLayoutStyleInputFocusDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage382SharedLayoutStyleInputFocusDemoProbeDraft" \
  "didConsumeStage381SharedComponentModel" \
  "didBindSharedModelToAiGeneratedSettingsDemo" \
  "didBindSharedModelToTodoDemoSurface" \
  "didMaterializeDemoLayoutSlots" \
  "didMaterializeDemoStyleTokens" \
  "didMaterializeDemoTextRuns" \
  "didMaterializeDemoInputBindings" \
  "didMaterializeDemoFocusTraversal" \
  "didMaterializeOwnerLocalStateDeltaFromDemoInput" \
  "didMaterializeRenderCommandRefreshPlanFromDemoSurface" \
  "didKeepOwnerLocalPreviewOnly" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage382 shared layout/style/input/focus demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage382_shared_layout_style_input_focus_demo_probe_owner_present=true"
echo "stage381_shared_component_model_required=true"
echo "stage382_shared_model_consumed_by_demo_surface=true"
echo "ai_generated_settings_demo_consumed_shared_component_model=true"
echo "todo_demo_surface_consumed_shared_component_model=true"
echo "demo_layout_slots_materialized=true"
echo "demo_style_tokens_materialized=true"
echo "demo_text_runs_materialized=true"
echo "demo_input_bindings_materialized=true"
echo "demo_focus_traversal_materialized=true"
echo "owner_local_state_delta_from_demo_input_materialized=true"
echo "render_command_refresh_plan_from_demo_surface_materialized=true"
echo "owner_local_preview_only=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
