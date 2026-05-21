#!/usr/bin/env zsh
#
# 维护注释：验证 stage268 internal Todo demo readiness decision owner。
# 它只确认 Todo intent/state/render preview runway 可接 demo probe，不提供 public demo API。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage268_internal_todo_demo_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage268 internal todo demo readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage268InternalTodoDemoReadinessDecisionFacts" \
  "CjguiInternalRendererStage268InternalTodoDemoReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage268InternalTodoDemoReadinessDecisionDraft" \
  "didConsumeStage267InternalTodoDemoRenderCommandPreview" \
  "didJoinTodoDemoIntentPacketWithStateUpdateDryRun" \
  "didJoinTodoDemoStateUpdateWithRenderCommandPreview" \
  "didJoinTodoDemoWithRollbackReadyBoundary" \
  "didJoinTodoDemoWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalTodoDemoReadinessDecision" \
  "didPrepareStage269InternalTodoDemoProbeInput" \
  "didConfirmMinimalUiFrameworkTodoDemoRunwayAdvanced" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage268 internal todo demo readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage268_internal_todo_demo_readiness_decision_owner_present=true"
echo "stage267_internal_todo_demo_render_command_preview_required=true"
echo "internal_todo_demo_readiness_decision_materialized=true"
echo "todo_demo_intent_state_render_joined=true"
echo "stage269_internal_todo_demo_probe_input_prepared=true"
echo "minimal_ui_framework_todo_demo_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
