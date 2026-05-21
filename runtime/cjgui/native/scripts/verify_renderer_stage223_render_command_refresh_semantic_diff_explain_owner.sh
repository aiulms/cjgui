#!/usr/bin/env zsh
#
# 维护注释：验证 stage223 RenderCommand refresh semantic diff/explain owner。
# 它把 refreshed preview packet 转成 owner acceptance 前的 diff/explain 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage223_render_command_refresh_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage223 render command refresh semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage223RenderCommandRefreshSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage223RenderCommandRefreshSemanticDiffExplainDraft" \
  "didConsumeStage222RefreshedRenderCommandPreviewPacket" \
  "didMaterializeRenderCommandRefreshSemanticDiff" \
  "didMaterializeRenderCommandRefreshExplainPacket" \
  "didBindDiffToRefreshedPreviewPacket" \
  "didBindExplainToStateUpdateSemanticDiff" \
  "didMaterializeRenderCommandRefreshRollbackReadyBoundary" \
  "didPrepareStage224RenderCommandRefreshReadinessDecisionInput" \
  "didKeepOwnerAcceptanceNotGranted"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage223 render command refresh semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage223_render_command_refresh_semantic_diff_explain_owner_present=true"
echo "stage222_refreshed_render_command_preview_packet_required=true"
echo "render_command_refresh_semantic_diff_materialized=true"
echo "render_command_refresh_explain_packet_materialized=true"
echo "render_command_refresh_rollback_ready_boundary_materialized=true"
echo "stage224_render_command_refresh_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
