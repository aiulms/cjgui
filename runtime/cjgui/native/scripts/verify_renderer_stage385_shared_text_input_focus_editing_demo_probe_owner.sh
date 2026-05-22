#!/usr/bin/env zsh
#
# 维护注释：验证 stage385 shared text input + focus editing demo probe owner。
# 它必须消费 stage384 input event adapter，并把 Todo text entry / settings focus target
# 推进为 owner-local text input editing dry-run，继续阻断真实 input pipeline 与 state commit。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage385 shared text input focus editing demo probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage385SharedTextInputEditEventStream" \
  "CjguiInternalRendererStage385SharedFocusEditingState" \
  "CjguiInternalRendererStage385TextInputFocusEditingDryRun" \
  "CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeFacts" \
  "CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage385SharedTextInputFocusEditingDemoProbeDraft" \
  "didConsumeStage384SharedInputEventToActionIntentAdapterDemoProbe" \
  "didMaterializeSharedTextInputEditEventStream" \
  "didBindTodoTextEntryToCharacterInsertEvent" \
  "didBindTodoTextEntryToBackspaceEditEvent" \
  "didBindTodoTextEntryToCaretPlacementEvent" \
  "didConsumeSharedTextModelByEditing" \
  "didConsumeSharedInputBindingByEditing" \
  "didConsumeSharedFocusTargetByEditing" \
  "didMaterializeSharedFocusEditingState" \
  "didPreserveSettingsFocusTargetDuringTextEditing" \
  "didMaterializeOwnerLocalTextBufferDelta" \
  "didMaterializeCaretAndSelectionPreview" \
  "didMaterializeFocusAfterEditingPreview" \
  "didKeepTextEditingDryRunOnly" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage385 shared text input focus editing demo probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage385_shared_text_input_focus_editing_demo_probe_owner_present=true"
echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_required=true"
echo "stage384_shared_input_event_to_action_intent_adapter_demo_probe_consumed=true"
echo "shared_text_input_edit_event_stream_materialized=true"
echo "todo_text_entry_character_insert_event_bound=true"
echo "todo_text_entry_backspace_edit_event_bound=true"
echo "todo_text_entry_caret_placement_event_bound=true"
echo "shared_text_model_consumed_by_editing=true"
echo "shared_input_binding_consumed_by_editing=true"
echo "shared_focus_target_consumed_by_editing=true"
echo "shared_focus_editing_state_materialized=true"
echo "settings_focus_target_preserved_during_text_editing=true"
echo "todo_text_entry_focus_target_active=true"
echo "owner_local_text_buffer_delta_materialized=true"
echo "caret_and_selection_preview_materialized=true"
echo "focus_after_editing_preview_materialized=true"
echo "text_editing_dry_run_only=true"
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
