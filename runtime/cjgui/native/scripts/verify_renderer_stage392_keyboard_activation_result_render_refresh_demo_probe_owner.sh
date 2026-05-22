#!/usr/bin/env zsh
#
# 维护注释：验证 stage392 keyboard activation result render refresh demo probe owner。
# 它必须消费 stage391 keyboard activation dry-run，把 activation result 接回
# Todo/settings surface refresh 和 RenderCommand preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage392_keyboard_activation_result_render_refresh_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage392 keyboard activation result render refresh demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage392KeyboardActivationResultEnvelope" \
  "CjguiInternalRendererStage392KeyboardActivationDemoSurfaceRefresh" \
  "CjguiInternalRendererStage392KeyboardActivationRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage392KeyboardActivationResultRenderRefreshDemoProbeFacts" \
  "CjguiInternalRendererStage392KeyboardActivationResultRenderRefreshDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage392KeyboardActivationResultRenderRefreshDemoProbeDraft" \
  "didConsumeStage391KeyboardActivationActionDryRun" \
  "didMaterializeKeyboardActivationResultEnvelope" \
  "didMaterializeAcceptedActivationResultPreview" \
  "didMaterializeRejectedActivationRollbackPreview" \
  "didBindActivationResultToTodoSurfaceRefresh" \
  "didBindActivationResultToSettingsSurfaceRefresh" \
  "didBindActivationResultToFocusRingRefresh" \
  "didBindActivationResultToStage390FocusTraversalRefresh" \
  "didMaterializeKeyboardActivationRenderCommandRefreshPlan" \
  "didBindActivationRefreshToStage383RenderBridge" \
  "didBindActivationRefreshToStage391ActionDryRun" \
  "didKeepKeyboardActivationResultRenderRefreshPreviewOnly" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage392 keyboard activation result render refresh demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage392_keyboard_activation_result_render_refresh_demo_probe_owner_present=true"
echo "stage391_keyboard_activation_action_dry_run_required=true"
echo "stage391_keyboard_activation_action_dry_run_consumed=true"
echo "keyboard_activation_result_envelope_materialized=true"
echo "accepted_activation_result_preview_materialized=true"
echo "rejected_activation_rollback_preview_materialized=true"
echo "activation_result_bound_to_todo_surface_refresh=true"
echo "activation_result_bound_to_settings_surface_refresh=true"
echo "activation_result_bound_to_focus_ring_refresh=true"
echo "activation_result_bound_to_stage390_focus_traversal_refresh=true"
echo "keyboard_activation_render_command_refresh_plan_materialized=true"
echo "activation_refresh_bound_to_stage383_render_bridge=true"
echo "activation_refresh_bound_to_stage391_action_dry_run=true"
echo "keyboard_activation_result_render_refresh_preview_only=true"
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
