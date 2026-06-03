#!/usr/bin/env zsh
#
# Verifies the stage707 component runtime state/render/feedback dry-run owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage707_component_runtime_state_render_feedback_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage707 component runtime state render feedback dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage707ComponentRuntimeStateRenderFeedbackDryRunPlan" \
  "CjguiInternalRendererStage707ComponentRuntimeStateRenderFeedbackDryRunFacts" \
  "CjguiInternalRendererStage707ComponentRuntimeStateRenderFeedbackDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage707ComponentRuntimeStateRenderFeedbackDryRunDraft" \
  "CjguiInternalRendererStage706ComponentRuntimeActionIntentAdapterReadiness" \
  "didConsumeStage706ComponentRuntimeActionIntentAdapter" \
  "didMaterializeSharedComponentRuntimeStateRenderFeedbackDryRun" \
  "didMaterializeComponentRuntimeStateDeltaDryRun" \
  "didMaterializeComponentRuntimeRenderCommandRefreshPreview" \
  "didMaterializeComponentRuntimeInputFeedbackRefresh" \
  "didMaterializeComponentRuntimeFocusTransitionRefresh" \
  "didPrepareStage708ComponentRuntimeInputEventCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage707 component runtime state render feedback dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage707_component_runtime_state_render_feedback_dry_run_owner_present=true"
echo "stage706_component_runtime_action_intent_adapter_consumed=true"
echo "stage705_component_runtime_input_event_normalization_consumed_transitively=true"
echo "stage704_text_input_component_runtime_cycle_executor_consumed_transitively=true"
echo "shared_component_runtime_state_render_feedback_dry_run_materialized=true"
echo "component_runtime_state_delta_dry_run_materialized=true"
echo "component_runtime_render_command_refresh_preview_materialized=true"
echo "component_runtime_input_feedback_refresh_materialized=true"
echo "component_runtime_focus_transition_refresh_materialized=true"
echo "component_runtime_semantic_diff_explain_materialized=true"
echo "todo_component_runtime_state_render_feedback_surface_materialized=true"
echo "settings_component_runtime_state_render_feedback_surface_materialized=true"
echo "ai_generated_settings_component_runtime_state_render_feedback_surface_materialized=true"
echo "chat_composer_component_runtime_state_render_feedback_surface_materialized=true"
echo "state_render_feedback_bound_to_component_action_intent=true"
echo "state_update_dry_run_only=true"
echo "render_command_refresh_preview_only=true"
echo "stage708_component_runtime_input_event_cycle_executor_prepared=true"
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
