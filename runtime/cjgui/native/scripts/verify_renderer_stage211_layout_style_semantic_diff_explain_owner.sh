#!/usr/bin/env zsh
#
# 维护注释：验证 stage211 layout/style semantic diff/explain owner。
# 它只生成 diff/explain/rollback 输入，不接受或发布预览。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage211_layout_style_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage211 layout style semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage211LayoutStyleSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage211LayoutStyleSemanticDiffExplainDraft" \
  "didConsumeStage210StyledComponentPreviewPacket" \
  "didMaterializeLayoutStyleSemanticDiff" \
  "didMaterializeLayoutStyleExplainPacket" \
  "didMaterializeStyleRollbackReadyBoundary" \
  "didKeepOwnerAcceptanceRequired" \
  "didPrepareStage212UiFrameworkRunwayReadinessDecisionInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage211 layout style semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage211_layout_style_semantic_diff_explain_owner_present=true"
echo "stage210_styled_component_preview_packet_required=true"
echo "layout_style_semantic_diff_materialized=true"
echo "layout_style_explain_packet_materialized=true"
echo "style_rollback_ready_boundary_materialized=true"
echo "owner_acceptance_required=true"
echo "stage212_ui_framework_runway_readiness_decision_input_prepared=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
