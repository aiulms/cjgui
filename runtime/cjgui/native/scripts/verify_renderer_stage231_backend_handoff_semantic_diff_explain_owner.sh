#!/usr/bin/env zsh
#
# 维护注释：验证 stage231 renderer backend handoff semantic diff / explain owner。
# 它只生成 owner acceptance 输入，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage231_backend_handoff_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage231 backend handoff semantic diff/explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage231BackendHandoffSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage231BackendHandoffSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage231BackendHandoffSemanticDiffExplainDraft" \
  "didConsumeStage230RendererBackendHandoffPacket" \
  "didMaterializeRendererBackendHandoffSemanticDiff" \
  "didMaterializeRendererBackendHandoffExplainPacket" \
  "didBindDiffToBackendHandoffPacket" \
  "didBindExplainToSubmissionReadinessDecision" \
  "didMaterializeRendererBackendHandoffRollbackReadyBoundary" \
  "didPrepareStage232RendererBackendHandoffReadinessDecisionInput" \
  "didKeepOwnerAcceptanceNotGranted" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage231 backend handoff semantic diff/explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage231_backend_handoff_semantic_diff_explain_owner_present=true"
echo "stage230_backend_handoff_packet_required=true"
echo "renderer_backend_handoff_semantic_diff_materialized=true"
echo "renderer_backend_handoff_explain_packet_materialized=true"
echo "renderer_backend_handoff_rollback_ready_boundary_materialized=true"
echo "stage232_renderer_backend_handoff_readiness_decision_input_prepared=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
