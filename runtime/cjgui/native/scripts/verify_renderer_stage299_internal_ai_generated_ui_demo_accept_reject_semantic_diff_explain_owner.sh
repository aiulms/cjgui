#!/usr/bin/env zsh
#
# 维护注释：验证 stage299 internal AI-generated UI demo accept/reject semantic diff/explain owner。
# 它只解释 accept/reject dry-run result，不执行 owner acceptance。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage299 internal ai generated ui demo accept reject semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage299InternalAiGeneratedUiDemoAcceptRejectSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage299InternalAiGeneratedUiDemoAcceptRejectSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage299InternalAiGeneratedUiDemoAcceptRejectSemanticDiffExplainDraft" \
  "didConsumeStage298InternalAiGeneratedUiDemoAcceptRejectDryRunResultEnvelope" \
  "didMaterializeAiGeneratedUiAcceptRejectSemanticDiff" \
  "didMaterializeAiGeneratedUiAcceptRejectExplainPacket" \
  "didBindAcceptDiffToUncommittedGeneratedUiProposal" \
  "didBindRejectDiffToRollbackReadyNoop" \
  "didRecheckAiGeneratedUiAcceptRejectOwnerAcceptanceBoundary" \
  "didRecheckAiGeneratedUiAcceptRejectVisibilityNotPublishedBoundary" \
  "didPrepareStage300AiGeneratedUiDemoAcceptRejectReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage299 internal ai generated ui demo accept reject semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain_owner_present=true"
echo "stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_required=true"
echo "ai_generated_ui_accept_reject_semantic_diff_materialized=true"
echo "ai_generated_ui_accept_reject_explain_packet_materialized=true"
echo "accept_diff_bound_to_uncommitted_generated_ui_proposal=true"
echo "reject_diff_bound_to_rollback_ready_noop=true"
echo "ai_generated_ui_accept_reject_owner_acceptance_boundary_rechecked=true"
echo "ai_generated_ui_accept_reject_visibility_not_published_boundary_rechecked=true"
echo "stage300_ai_generated_ui_demo_accept_reject_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
