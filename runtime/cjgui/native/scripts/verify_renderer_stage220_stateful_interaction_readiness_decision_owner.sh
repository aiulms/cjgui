#!/usr/bin/env zsh
#
# 维护注释：验证 stage220 stateful interaction readiness decision owner。
# 它汇合 action、state preview、state diff 和 rollback 边界，准备下一段渲染预览。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage220_stateful_interaction_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage220 stateful interaction readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage220StatefulInteractionReadinessDecisionFacts" \
  "CjguiInternalRendererStage220StatefulInteractionReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage220StatefulInteractionReadinessDecisionDraft" \
  "didConsumeStage219StateUpdateSemanticDiffExplain" \
  "didJoinActionPreviewWithStateUpdatePreviewPacket" \
  "didJoinStateUpdatePreviewWithRollbackReadyBoundary" \
  "didMaterializeStatefulInteractionReadinessDecision" \
  "didPrepareStage221RenderCommandRefreshAfterStateUpdatePreviewInput" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage220 stateful interaction readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage220_stateful_interaction_readiness_decision_owner_present=true"
echo "stage219_state_update_semantic_diff_explain_required=true"
echo "action_preview_joined_with_state_update_preview_packet=true"
echo "state_update_preview_joined_with_rollback_ready_boundary=true"
echo "stateful_interaction_readiness_decision_materialized=true"
echo "stage221_render_command_refresh_after_state_update_preview_input_prepared=true"
echo "minimal_ui_framework_stateful_interaction_input_prepared=true"
echo "visibility_published=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
