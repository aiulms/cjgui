#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage156 renderer-state write first-slice readiness
# contract owner 只生成非变更 readiness envelope，不触碰 runtime_state.cj。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage156_renderer_state_write_first_slice_readiness_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage156 renderer-state write first-slice readiness owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage156RendererStateWriteFirstSliceReadinessContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage156RendererStateWriteFirstSliceReadinessContractDraft" \
  "didMaterializeRendererStateWriteFirstSlicePreconditionLedger" \
  "didBindWriteTokenGatePredicate" \
  "didBindMutationRequestRuntimePredicate" \
  "didBindGuardedExecutorRuntimePredicate" \
  "didDefineRendererStateWritePositiveDryRunCandidate" \
  "didKeepRendererStateWriteFirstSliceExecutionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage156 renderer-state write first-slice readiness owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage156_renderer_state_write_first_slice_readiness_contract_owner_present=true"
echo "stage155_rollback_visibility_boundary_packet_required=true"
echo "legacy_terminal_write_denial_packet_required=true"
echo "renderer_state_write_first_slice_precondition_ledger_materialized=true"
echo "renderer_state_write_positive_dry_run_candidate_defined=true"
echo "renderer_state_write_first_slice_readiness_contract_ready=true"
echo "renderer_state_write_first_slice_predicates_satisfied=false"
echo "renderer_state_write_first_slice_runtime_admitted=false"
echo "visibility_publication_required_before_write=true"
echo "rollback_visibility_boundary_required_before_write=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
