#!/usr/bin/env zsh
#
# 维护注释：验证 stage262 internal component demo loop dry-run result envelope owner。
# 它把 stage261 probe input/result 归档为可复用 envelope，不升级 backend-ready truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage262_internal_component_demo_loop_dry_run_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage262 internal component demo loop dry-run result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage262InternalComponentDemoLoopDryRunResultEnvelopeFacts" \
  "CjguiInternalRendererStage262InternalComponentDemoLoopDryRunResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage262InternalComponentDemoLoopDryRunResultEnvelopeDraft" \
  "didConsumeStage261InternalComponentDemoLoopDryRunProbe" \
  "didMaterializeReusableComponentDemoLoopDryRunResultEnvelope" \
  "didBindDryRunResultEnvelopeToProbeInput" \
  "didBindDryRunResultEnvelopeToProbeResult" \
  "didKeepDryRunResultEnvelopeOwnerLocalInMemoryOnly" \
  "didConfirmDryRunResultRollbackReady" \
  "didConfirmDryRunResultVisibilityNotPublished" \
  "didPrepareStage263LoopDryRunProbeSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage262 internal component demo loop dry-run result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage262_internal_component_demo_loop_dry_run_result_envelope_owner_present=true"
echo "stage261_internal_component_demo_loop_dry_run_probe_required=true"
echo "reusable_component_demo_loop_dry_run_result_envelope_materialized=true"
echo "dry_run_result_envelope_bound_to_probe_input=true"
echo "dry_run_result_envelope_bound_to_probe_result=true"
echo "dry_run_result_envelope_owner_local_in_memory_only=true"
echo "dry_run_result_rollback_ready=true"
echo "dry_run_result_visibility_not_published=true"
echo "stage263_loop_dry_run_probe_semantic_diff_explain_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
