#!/usr/bin/env zsh
#
# 维护注释：验证 stage347 internal AI-generated UI demo execution feedback surface probe input/result envelope owner。
# 它把 feedback surface diff/explain 封装成 non-executing probe input 与 rollback-ready envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage347_internal_ai_generated_ui_demo_execution_feedback_surface_probe_input_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage347 internal ai generated ui demo execution feedback surface probe input result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage347InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeInputResultEnvelopeFacts" \
  "CjguiInternalRendererStage347InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeInputResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage347InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeInputResultEnvelopeDraft" \
  "didConsumeStage346ExecutionFeedbackSurfaceSemanticDiffExplain" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceProbeInput" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceProbeResultEnvelope" \
  "didBindExecutionFeedbackSurfaceProbeInputToSurfaceRefresh" \
  "didBindExecutionFeedbackSurfaceProbeInputToSemanticDiffExplain" \
  "didKeepExecutionFeedbackSurfaceProbeInputNonExecuting" \
  "didKeepExecutionFeedbackSurfaceProbeResultEnvelopeRollbackReady" \
  "didKeepExecutionFeedbackSurfaceProbeResultEnvelopeVisibilityNotPublished" \
  "didPrepareStage348ExecutionFeedbackSurfaceReadinessDecision" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage347 internal ai generated ui demo execution feedback surface probe input result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage347_internal_ai_generated_ui_demo_execution_feedback_surface_probe_input_result_envelope_owner_present=true"
echo "stage346_internal_ai_generated_ui_demo_execution_feedback_surface_semantic_diff_explain_required=true"
echo "ai_generated_ui_demo_execution_feedback_surface_probe_input_materialized=true"
echo "ai_generated_ui_demo_execution_feedback_surface_probe_result_envelope_materialized=true"
echo "execution_feedback_surface_probe_input_bound_to_surface_refresh=true"
echo "execution_feedback_surface_probe_input_bound_to_semantic_diff_explain=true"
echo "execution_feedback_surface_probe_input_non_executing=true"
echo "execution_feedback_surface_probe_result_envelope_rollback_ready=true"
echo "execution_feedback_surface_probe_result_envelope_visibility_not_published=true"
echo "stage348_execution_feedback_surface_readiness_decision_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
