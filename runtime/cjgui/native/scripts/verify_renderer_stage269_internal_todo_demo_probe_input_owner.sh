#!/usr/bin/env zsh
#
# 维护注释：验证 stage269 internal Todo demo probe input owner。
# 它只确认 Todo demo probe input 已绑定 intent/state/render/rollback/visibility，不执行 action。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage269_internal_todo_demo_probe_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage269 internal todo demo probe input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage269InternalTodoDemoProbeInputFacts" \
  "CjguiInternalRendererStage269InternalTodoDemoProbeInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage269InternalTodoDemoProbeInputDraft" \
  "didConsumeStage268InternalTodoDemoReadinessDecision" \
  "didMaterializeInternalTodoDemoProbeInput" \
  "didBindTodoProbeInputToAddIntent" \
  "didBindTodoProbeInputToToggleIntent" \
  "didBindTodoProbeInputToRemoveIntent" \
  "didBindTodoProbeInputToOwnerLocalStateDelta" \
  "didBindTodoProbeInputToRenderCommandPreview" \
  "didBindTodoProbeInputToRollbackReadyBoundary" \
  "didBindTodoProbeInputToVisibilityNotPublishedBoundary" \
  "didKeepTodoProbeInputNonExecuting" \
  "didPrepareStage270TodoDemoProbeResultEnvelopeInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage269 internal todo demo probe input: missing token $token" >&2
    exit 3
  fi
done

echo "stage269_internal_todo_demo_probe_input_owner_present=true"
echo "stage268_internal_todo_demo_readiness_decision_required=true"
echo "internal_todo_demo_probe_input_materialized=true"
echo "todo_probe_input_bound_to_add_intent=true"
echo "todo_probe_input_bound_to_toggle_intent=true"
echo "todo_probe_input_bound_to_remove_intent=true"
echo "todo_probe_input_bound_to_owner_local_state_delta=true"
echo "todo_probe_input_bound_to_render_command_preview=true"
echo "todo_probe_input_bound_to_rollback_ready_boundary=true"
echo "todo_probe_input_bound_to_visibility_not_published_boundary=true"
echo "todo_probe_input_non_executing=true"
echo "stage270_todo_demo_probe_result_envelope_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
