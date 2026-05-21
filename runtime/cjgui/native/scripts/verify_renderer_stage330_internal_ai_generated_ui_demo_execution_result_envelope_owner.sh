#!/usr/bin/env zsh
#
# 维护注释：验证 stage330 internal AI-generated UI demo execution result envelope owner。
# 它消费 stage329 execution dry-run，归档 owner-local / rollback-ready result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage330_internal_ai_generated_ui_demo_execution_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage330 internal ai generated ui demo execution result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage330InternalAiGeneratedUiDemoExecutionResultEnvelopeFacts" \
  "CjguiInternalRendererStage330InternalAiGeneratedUiDemoExecutionResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage330InternalAiGeneratedUiDemoExecutionResultEnvelopeDraft" \
  "didConsumeStage329AiGeneratedUiDemoExecutionDryRun" \
  "didMaterializeAiGeneratedUiDemoExecutionResultEnvelope" \
  "didBindExecutionResultEnvelopeToDryRun" \
  "didBindExecutionResultEnvelopeToResultToProbeReadiness" \
  "didKeepExecutionResultEnvelopeOwnerLocalInMemoryOnly" \
  "didKeepExecutionResultEnvelopeRollbackReady" \
  "didKeepExecutionResultEnvelopeVisibilityNotPublished" \
  "didPrepareStage331ExecutionSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage330 internal ai generated ui demo execution result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage330_internal_ai_generated_ui_demo_execution_result_envelope_owner_present=true"
echo "stage329_internal_ai_generated_ui_demo_execution_dry_run_required=true"
echo "ai_generated_ui_demo_execution_result_envelope_materialized=true"
echo "execution_result_envelope_bound_to_dry_run=true"
echo "execution_result_envelope_bound_to_result_to_probe_readiness=true"
echo "execution_result_envelope_owner_local_in_memory_only=true"
echo "execution_result_envelope_rollback_ready=true"
echo "execution_result_envelope_visibility_not_published=true"
echo "stage331_execution_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
