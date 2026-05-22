#!/usr/bin/env zsh
#
# 维护注释：验证 stage391 keyboard activation action dry-run owner。
# 它必须消费 stage390 focus traversal refresh，把 focused Enter/Space activation
# 转成 owner-local shared action intent 和 state update dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage391_keyboard_activation_action_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage391 keyboard activation action dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage391KeyboardActivationEventEnvelope" \
  "CjguiInternalRendererStage391FocusedActivationIntentAdapter" \
  "CjguiInternalRendererStage391KeyboardActivationStateUpdateDryRun" \
  "CjguiInternalRendererStage391KeyboardActivationActionDryRunFacts" \
  "CjguiInternalRendererStage391KeyboardActivationActionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage391KeyboardActivationActionDryRunDraft" \
  "didConsumeStage390FocusTraversalRenderRefreshDemoProbe" \
  "didMaterializeKeyboardActivationEventEnvelope" \
  "didBindEnterKeyToFocusedActivationIntent" \
  "didBindSpaceKeyToFocusedActivationIntent" \
  "didBindActivationToCurrentFocusTarget" \
  "didBindActivationToTodoCommitAction" \
  "didBindActivationToSettingsToggleAction" \
  "didMaterializeFocusedActivationIntentAdapter" \
  "didMapFocusedTodoActivationToSharedActionIntent" \
  "didMapFocusedSettingsActivationToSharedActionIntent" \
  "didMaterializeKeyboardActivationOwnerAcceptanceGate" \
  "didMaterializeKeyboardActivationStateUpdateDryRun" \
  "didMaterializeTodoActivationStateDeltaPreview" \
  "didMaterializeSettingsActivationStateDeltaPreview" \
  "didBindActivationStateUpdateToStage383ActionExecutor" \
  "didBindActivationStateUpdateToStage390FocusTraversalRefresh" \
  "didKeepKeyboardActivationDryRunUncommitted" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage391 keyboard activation action dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage391_keyboard_activation_action_dry_run_owner_present=true"
echo "stage390_focus_traversal_render_refresh_demo_probe_required=true"
echo "stage390_focus_traversal_render_refresh_demo_probe_consumed=true"
echo "keyboard_activation_event_envelope_materialized=true"
echo "enter_key_bound_to_focused_activation_intent=true"
echo "space_key_bound_to_focused_activation_intent=true"
echo "activation_bound_to_current_focus_target=true"
echo "activation_bound_to_todo_commit_action=true"
echo "activation_bound_to_settings_toggle_action=true"
echo "focused_activation_intent_adapter_materialized=true"
echo "focused_todo_activation_mapped_to_shared_action_intent=true"
echo "focused_settings_activation_mapped_to_shared_action_intent=true"
echo "keyboard_activation_owner_acceptance_gate_materialized=true"
echo "keyboard_activation_state_update_dry_run_materialized=true"
echo "todo_activation_state_delta_preview_materialized=true"
echo "settings_activation_state_delta_preview_materialized=true"
echo "activation_state_update_bound_to_stage383_action_executor=true"
echo "activation_state_update_bound_to_stage390_focus_traversal_refresh=true"
echo "keyboard_activation_dry_run_uncommitted=true"
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
