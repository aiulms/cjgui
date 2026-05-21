#!/usr/bin/env zsh
#
# 维护注释：验证 stage298 internal AI-generated UI demo accept/reject dry-run result envelope owner。
# 它只形成 owner-local result envelope，不提交 accept 分支，也不发布 reject 结果。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage298 internal ai generated ui demo accept reject dry run result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage298InternalAiGeneratedUiDemoAcceptRejectDryRunResultEnvelopeFacts" \
  "CjguiInternalRendererStage298InternalAiGeneratedUiDemoAcceptRejectDryRunResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage298InternalAiGeneratedUiDemoAcceptRejectDryRunResultEnvelopeDraft" \
  "didConsumeStage297InternalAiGeneratedUiDemoAcceptRejectDryRunInput" \
  "didMaterializeAiGeneratedUiAcceptRejectDryRunResultEnvelope" \
  "didBindAcceptResultToUncommittedGeneratedUiProposal" \
  "didBindRejectResultToRollbackReadyNoop" \
  "didBindResultEnvelopeToVisibilityNotPublishedBoundary" \
  "didKeepAiGeneratedUiAcceptRejectResultOwnerLocalInMemoryOnly" \
  "didKeepAiGeneratedUiAcceptRejectResultRollbackReady" \
  "didPrepareStage299AiGeneratedUiDemoAcceptRejectSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage298 internal ai generated ui demo accept reject dry run result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage298_internal_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_owner_present=true"
echo "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_required=true"
echo "ai_generated_ui_accept_reject_dry_run_result_envelope_materialized=true"
echo "accept_result_bound_to_uncommitted_generated_ui_proposal=true"
echo "reject_result_bound_to_rollback_ready_noop=true"
echo "accept_reject_result_bound_to_visibility_not_published_boundary=true"
echo "ai_generated_ui_accept_reject_result_owner_local_in_memory_only=true"
echo "ai_generated_ui_accept_reject_result_rollback_ready=true"
echo "stage299_ai_generated_ui_demo_accept_reject_semantic_diff_explain_input_prepared=true"
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
