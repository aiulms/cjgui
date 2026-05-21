#!/usr/bin/env zsh
#
# 维护注释：验证 stage227 renderer submission semantic diff/explain owner。
# 它生成 submission preview 的 diff/explain/rollback boundary，不接受变更。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage227_renderer_submission_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage227 renderer submission semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage227RendererSubmissionSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage227RendererSubmissionSemanticDiffExplainDraft" \
  "didConsumeStage226RendererSubmissionPreviewPacket" \
  "didMaterializeRendererSubmissionSemanticDiff" \
  "didMaterializeRendererSubmissionExplainPacket" \
  "didMaterializeRendererSubmissionRollbackReadyBoundary" \
  "didKeepOwnerAcceptanceRequired" \
  "didPrepareStage228RendererSubmissionReadinessDecisionInput" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage227 renderer submission semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage227_renderer_submission_semantic_diff_explain_owner_present=true"
echo "stage226_renderer_submission_preview_packet_required=true"
echo "renderer_submission_semantic_diff_materialized=true"
echo "renderer_submission_explain_packet_materialized=true"
echo "renderer_submission_rollback_ready_boundary_materialized=true"
echo "owner_acceptance_required=true"
echo "stage228_renderer_submission_readiness_decision_input_prepared=true"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
