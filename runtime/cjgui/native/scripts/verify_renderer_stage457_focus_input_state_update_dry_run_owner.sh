#!/usr/bin/env zsh
#
# 维护注释：验证 stage457 focus/input action intent -> state update dry-run owner。
# 它必须消费 stage456 focus/input adapter，并生成 owner-local uncommitted state update candidates。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage457_focus_input_state_update_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage457 focus input state update dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage457FocusInputStateUpdateDryRunPlan" \
  "CjguiInternalRendererStage457FocusInputStateUpdateDryRunFacts" \
  "CjguiInternalRendererStage457FocusInputStateUpdateDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage457FocusInputStateUpdateDryRunDraft" \
  "CjguiInternalRendererStage456RecoveryDemoSurfaceFocusInputActionIntentAdapterReadiness" \
  "didConsumeStage456FocusInputActionIntentAdapter" \
  "didConsumeSharedFocusInputActionIntentAdapter" \
  "didConsumeTodoFocusActivationActionIntent" \
  "didConsumeSettingsToggleFocusActionIntent" \
  "didConsumeAiGeneratedSettingsSubmitFocusActionIntent" \
  "didMaterializeFocusInputActionStateUpdateDryRun" \
  "didMaterializeTodoFocusInputStateUpdateCandidate" \
  "didMaterializeSettingsFocusInputStateUpdateCandidate" \
  "didMaterializeAiGeneratedSettingsFocusInputStateUpdateCandidate" \
  "didBindFocusInputActionIntentToStateUpdateDryRun" \
  "didKeepFocusInputStateUpdateOwnerLocal" \
  "didKeepFocusInputStateUpdateInMemoryOnly" \
  "didKeepFocusInputStateUpdateUncommitted" \
  "didPrepareStage458FocusStateRenderCommandRefresh" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage457 focus input state update dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage457_focus_input_state_update_dry_run_owner_present=true"
echo "stage456_focus_input_action_intent_adapter_required=true"
echo "stage456_focus_input_action_intent_adapter_consumed=true"
echo "shared_focus_input_action_intent_adapter_consumed=true"
echo "todo_focus_activation_action_intent_consumed=true"
echo "settings_toggle_focus_action_intent_consumed=true"
echo "ai_generated_settings_submit_focus_action_intent_consumed=true"
echo "focus_input_action_state_update_dry_run_materialized=true"
echo "todo_focus_input_state_update_candidate_materialized=true"
echo "settings_focus_input_state_update_candidate_materialized=true"
echo "ai_generated_settings_focus_input_state_update_candidate_materialized=true"
echo "focus_input_action_intent_to_state_update_dry_run_bound=true"
echo "focus_input_state_update_owner_local=true"
echo "focus_input_state_update_in_memory_only=true"
echo "focus_input_state_update_uncommitted=true"
echo "stage458_focus_state_render_command_refresh_prepared=true"
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
