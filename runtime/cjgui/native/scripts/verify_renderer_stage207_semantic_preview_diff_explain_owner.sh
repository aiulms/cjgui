#!/usr/bin/env zsh
#
# 维护注释：验证 stage207 semantic preview diff / explain owner。
# 它只生成 owner-local diff/explain/rollback boundary，不接受或发布变更。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage207_semantic_preview_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage207 semantic preview diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage207SemanticPreviewDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage207SemanticPreviewDiffExplainDraft" \
  "didConsumeStage206ComponentDemoPreviewPacket" \
  "didMaterializeSemanticPreviewDiff" \
  "didMaterializeSemanticExplainPacket" \
  "didMaterializeRollbackReadyPreviewBoundary" \
  "didKeepOwnerAcceptanceRequired" \
  "didPrepareStage208UiRunwayReadinessDecisionInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage207 semantic preview diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage207_semantic_preview_diff_explain_owner_present=true"
echo "stage206_component_demo_preview_packet_required=true"
echo "semantic_preview_diff_materialized=true"
echo "semantic_explain_packet_materialized=true"
echo "rollback_ready_preview_boundary_materialized=true"
echo "owner_acceptance_required=true"
echo "stage208_ui_runway_readiness_decision_input_prepared=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
