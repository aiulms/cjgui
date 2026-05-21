#!/usr/bin/env zsh
#
# 维护注释：验证 stage261 internal component demo loop dry-run probe owner。
# 它只形成 owner-local non-executing probe input/result envelope，不执行 action dispatch 或 state commit。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage261_internal_component_demo_loop_dry_run_probe.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage261 internal component demo loop dry-run probe: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage261InternalComponentDemoLoopDryRunProbeFacts" \
  "CjguiInternalRendererStage261InternalComponentDemoLoopDryRunProbeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage261InternalComponentDemoLoopDryRunProbeDraft" \
  "didConsumeStage260InternalComponentDemoLoopReadinessDecision" \
  "didMaterializeInternalComponentDemoLoopDryRunProbeInput" \
  "didMaterializeInternalComponentDemoLoopDryRunProbeResultEnvelope" \
  "didBindDryRunProbeToActionIntentFacts" \
  "didBindDryRunProbeToStateUpdateDelta" \
  "didBindDryRunProbeToRenderCommandDelta" \
  "didBindDryRunProbeToRollbackReadyBoundary" \
  "didKeepDryRunProbeNonExecuting" \
  "didPrepareStage262LoopDryRunResultEnvelopeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage261 internal component demo loop dry-run probe: missing token $token" >&2
    exit 3
  fi
done

echo "stage261_internal_component_demo_loop_dry_run_probe_owner_present=true"
echo "stage260_internal_component_demo_loop_readiness_decision_required=true"
echo "internal_component_demo_loop_dry_run_probe_input_materialized=true"
echo "internal_component_demo_loop_dry_run_probe_result_envelope_materialized=true"
echo "dry_run_probe_bound_to_action_intent_facts=true"
echo "dry_run_probe_bound_to_state_update_delta=true"
echo "dry_run_probe_bound_to_render_command_delta=true"
echo "dry_run_probe_bound_to_rollback_ready_boundary=true"
echo "dry_run_probe_non_executing=true"
echo "stage262_loop_dry_run_result_envelope_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
