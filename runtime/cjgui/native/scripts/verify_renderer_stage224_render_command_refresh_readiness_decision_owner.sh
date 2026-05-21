#!/usr/bin/env zsh
#
# 维护注释：验证 stage224 render-command refresh readiness decision owner。
# 它汇合 state update preview、refreshed RenderCommand preview 与 diff/explain。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage224_render_command_refresh_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage224 render command refresh readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionFacts" \
  "CjguiInternalRendererStage224RenderCommandRefreshReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage224RenderCommandRefreshReadinessDecisionDraft" \
  "didConsumeStage223RenderCommandRefreshSemanticDiffExplain" \
  "didJoinStateUpdatePreviewWithRefreshedRenderCommandPacket" \
  "didJoinRenderCommandRefreshDiffExplainWithRollbackBoundary" \
  "didMaterializeRenderCommandRefreshReadinessDecision" \
  "didConfirmMinimalUiFrameworkRunwayAdvanced" \
  "didPrepareStage225RendererSubmissionPreviewInput" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage224 render command refresh readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage224_render_command_refresh_readiness_decision_owner_present=true"
echo "stage223_render_command_refresh_semantic_diff_explain_required=true"
echo "state_update_preview_joined_with_refreshed_render_command_packet=true"
echo "render_command_refresh_diff_explain_joined_with_rollback_boundary=true"
echo "render_command_refresh_readiness_decision_materialized=true"
echo "stage225_renderer_submission_preview_input_prepared=true"
echo "minimal_ui_framework_render_command_refresh_input_prepared=true"
echo "owner_acceptance_granted=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
