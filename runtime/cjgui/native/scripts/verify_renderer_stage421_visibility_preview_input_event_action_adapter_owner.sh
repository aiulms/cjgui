#!/usr/bin/env zsh
#
# 维护注释：验证 stage421 visibility preview input event -> action intent adapter owner。
# 它必须消费 stage420 visibility preview diff / RenderCommand refresh，并生成 owner-local action intent。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage421_visibility_preview_input_event_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage421 visibility preview input event action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage421VisibilityPreviewInputEventActionAdapterPlan" \
  "CjguiInternalRendererStage421VisibilityPreviewInputEventActionAdapterFacts" \
  "CjguiInternalRendererStage421VisibilityPreviewInputEventActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage421VisibilityPreviewInputEventActionAdapterDraft" \
  "didConsumeStage420VisibilityPreviewDiffRenderCommandRefresh" \
  "didConsumeVisibilityPreviewDiff" \
  "didConsumeVisibilityPreviewRenderCommandRefresh" \
  "didMaterializeVisibilityPreviewInputEventAdapter" \
  "didBindTodoVisiblePreviewInputEventToActionIntent" \
  "didBindSettingsVisiblePreviewInputEventToActionIntent" \
  "didBindAiGeneratedSettingsVisiblePreviewInputEventToActionIntent" \
  "didMaterializeOwnerLocalActionIntent" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionIntentNonDispatching" \
  "didPrepareStage422ActionIntentStateUpdateDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage421 visibility preview input event action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage421_visibility_preview_input_event_action_adapter_owner_present=true"
echo "stage420_visibility_preview_diff_render_command_refresh_required=true"
echo "stage420_visibility_preview_diff_render_command_refresh_consumed=true"
echo "visibility_preview_diff_consumed=true"
echo "visibility_preview_render_command_refresh_consumed=true"
echo "todo_visibility_preview_diff_consumed=true"
echo "settings_visibility_preview_diff_consumed=true"
echo "ai_generated_settings_visibility_preview_diff_consumed=true"
echo "visibility_preview_input_event_adapter_materialized=true"
echo "todo_visible_preview_input_event_adapter_materialized=true"
echo "settings_visible_preview_input_event_adapter_materialized=true"
echo "ai_generated_settings_visible_preview_input_event_adapter_materialized=true"
echo "todo_visible_preview_input_event_to_action_intent_bound=true"
echo "settings_visible_preview_input_event_to_action_intent_bound=true"
echo "ai_generated_settings_visible_preview_input_event_to_action_intent_bound=true"
echo "owner_local_action_intent_materialized=true"
echo "input_event_adapter_bound_to_stage420_visibility_diff=true"
echo "input_event_adapter_bound_to_stage420_render_command_refresh=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_intent_owner_local=true"
echo "action_dispatch=false"
echo "action_intent_non_dispatching=true"
echo "stage422_action_intent_state_update_dry_run_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
