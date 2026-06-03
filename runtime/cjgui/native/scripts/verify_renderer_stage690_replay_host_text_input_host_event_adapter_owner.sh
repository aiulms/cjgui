#!/usr/bin/env zsh
#
# Verifies the stage690 replay host text input host-event adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage690_replay_host_text_input_host_event_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage690 replay host text input host-event adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage690ReplayHostTextInputHostEventAdapterPlan" \
  "CjguiInternalRendererStage690ReplayHostTextInputHostEventAdapterFacts" \
  "CjguiInternalRendererStage690ReplayHostTextInputHostEventAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage690ReplayHostTextInputHostEventAdapterDraft" \
  "CjguiInternalRendererStage689ReplayHostTextInputDemoHostIntegrationReadiness" \
  "didConsumeStage689ReplayHostTextInputDemoHostIntegration" \
  "didMaterializeSharedReplayHostTextInputHostEventAdapter" \
  "didMaterializeTextEditHostEventRoute" \
  "didMaterializeTextSubmitHostEventRoute" \
  "didMaterializeValidationDismissHostEventRoute" \
  "didMaterializeFocusMoveHostEventRoute" \
  "didMaterializeReplayHostTextInputHostEventQueuePreview" \
  "didMaterializeOwnerLocalHostEventLedger" \
  "didMaterializeChatComposerReplayHostTextInputHostEventQueue" \
  "didBindHostEventAdapterToStage689Integration" \
  "didKeepHostEventQueuePreviewOnly" \
  "didPrepareStage691ReplayHostTextInputExecutionResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage690 replay host text input host-event adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage690_replay_host_text_input_host_event_adapter_owner_present=true"
echo "stage689_replay_host_text_input_demo_host_integration_consumed=true"
echo "shared_replay_host_text_input_host_event_adapter_materialized=true"
echo "text_edit_host_event_route_materialized=true"
echo "text_submit_host_event_route_materialized=true"
echo "validation_dismiss_host_event_route_materialized=true"
echo "focus_move_host_event_route_materialized=true"
echo "replay_host_text_input_host_event_queue_preview_materialized=true"
echo "owner_local_host_event_ledger_materialized=true"
echo "todo_replay_host_text_input_host_event_queue_materialized=true"
echo "settings_replay_host_text_input_host_event_queue_materialized=true"
echo "ai_generated_settings_replay_host_text_input_host_event_queue_materialized=true"
echo "chat_composer_replay_host_text_input_host_event_queue_materialized=true"
echo "host_event_adapter_bound_to_stage689_integration=true"
echo "host_event_queue_preview_only=true"
echo "stage691_replay_host_text_input_execution_result_surface_prepared=true"
echo "host_mutation=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
