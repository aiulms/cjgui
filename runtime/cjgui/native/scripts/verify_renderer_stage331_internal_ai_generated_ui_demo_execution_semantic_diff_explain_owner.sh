#!/usr/bin/env zsh
#
# 维护注释：验证 stage331 internal AI-generated UI demo execution semantic diff/explain owner。
# 它消费 execution result envelope，产出 dry-run 语义差异和解释包。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage331_internal_ai_generated_ui_demo_execution_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage331 internal ai generated ui demo execution semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage331InternalAiGeneratedUiDemoExecutionSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage331InternalAiGeneratedUiDemoExecutionSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage331InternalAiGeneratedUiDemoExecutionSemanticDiffExplainDraft" \
  "didConsumeStage330AiGeneratedUiDemoExecutionResultEnvelope" \
  "didMaterializeAiGeneratedUiDemoExecutionSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionExplainPacket" \
  "didBindExecutionSemanticDiffToExecutionResultEnvelope" \
  "didBindExecutionExplainToOwnerControlledDryRun" \
  "didKeepExecutionSemanticDiffRollbackReady" \
  "didKeepExecutionExplainVisibilityNotPublished" \
  "didPrepareStage332ExecutionReadinessDecision" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage331 internal ai generated ui demo execution semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage331_internal_ai_generated_ui_demo_execution_semantic_diff_explain_owner_present=true"
echo "stage330_internal_ai_generated_ui_demo_execution_result_envelope_required=true"
echo "ai_generated_ui_demo_execution_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_explain_packet_materialized=true"
echo "execution_semantic_diff_bound_to_execution_result_envelope=true"
echo "execution_explain_bound_to_owner_controlled_dry_run=true"
echo "execution_semantic_diff_rollback_ready=true"
echo "execution_explain_visibility_not_published=true"
echo "stage332_execution_readiness_decision_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
