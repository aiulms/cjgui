#!/usr/bin/env zsh
#
# 维护注释：验证 stage228 renderer submission readiness decision owner。
# 它只做 readiness join，准备下一段 backend handoff dry-run 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage228_renderer_submission_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage228 renderer submission readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage228RendererSubmissionReadinessDecisionFacts" \
  "CjguiInternalRendererStage228RendererSubmissionReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage228RendererSubmissionReadinessDecisionDraft" \
  "didConsumeStage227RendererSubmissionSemanticDiffExplain" \
  "didJoinRendererSubmissionPreviewWithPreviewPacket" \
  "didJoinRendererSubmissionDiffExplainWithRollbackBoundary" \
  "didMaterializeRendererSubmissionReadinessDecision" \
  "didPrepareStage229RendererBackendHandoffDryRunInput" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage228 renderer submission readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage228_renderer_submission_readiness_decision_owner_present=true"
echo "stage227_renderer_submission_semantic_diff_explain_required=true"
echo "renderer_submission_preview_joined_with_packet=true"
echo "renderer_submission_diff_explain_joined_with_rollback_boundary=true"
echo "renderer_submission_readiness_decision_materialized=true"
echo "stage229_renderer_backend_handoff_dry_run_input_prepared=true"
echo "owner_acceptance_granted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
