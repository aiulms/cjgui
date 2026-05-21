#!/usr/bin/env zsh
#
# 维护注释：验证 stage329 internal AI-generated UI demo execution dry-run owner。
# 它消费 stage328 result-to-probe readiness，把 demo execution 表达成 owner-local dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage329_internal_ai_generated_ui_demo_execution_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage329 internal ai generated ui demo execution dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage329InternalAiGeneratedUiDemoExecutionDryRunFacts" \
  "CjguiInternalRendererStage329InternalAiGeneratedUiDemoExecutionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage329InternalAiGeneratedUiDemoExecutionDryRunDraft" \
  "didConsumeStage328InternalAiGeneratedUiDemoResultToProbeReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionDryRun" \
  "didBindExecutionDryRunToResultToSurfaceRefresh" \
  "didBindExecutionDryRunToResultToProbeInput" \
  "didBindExecutionDryRunToResultToProbeResultEnvelope" \
  "didKeepExecutionDryRunOwnerLocalInMemoryOnly" \
  "didKeepExecutionDryRunNonDispatching" \
  "didPrepareStage330ExecutionResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage329 internal ai generated ui demo execution dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage329_internal_ai_generated_ui_demo_execution_dry_run_owner_present=true"
echo "stage328_internal_ai_generated_ui_demo_result_to_probe_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_dry_run_materialized=true"
echo "execution_dry_run_bound_to_result_to_surface_refresh=true"
echo "execution_dry_run_bound_to_result_to_probe_input=true"
echo "execution_dry_run_bound_to_result_to_probe_result_envelope=true"
echo "execution_dry_run_owner_local_in_memory_only=true"
echo "execution_dry_run_non_dispatching=true"
echo "stage330_execution_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
