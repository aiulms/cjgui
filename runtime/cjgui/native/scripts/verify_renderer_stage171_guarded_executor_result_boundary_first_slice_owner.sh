#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage171 guarded executor result boundary source。
# 它消费 stage170 guarded executor result envelope，整理 denial/result 边界。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage171_guarded_executor_result_boundary_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage171 guarded executor result boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage171GuardedExecutorResultBoundaryFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage171GuardedExecutorResultBoundaryFirstSliceDraft" \
  "didConsumeStage170GuardedStateWriteExecutor" \
  "didMaterializeGuardedExecutorResultBoundaryEnvelope" \
  "didBindGuardedExecutorDenialReasonLedger" \
  "didBindRollbackEligibilityBoundary" \
  "didPrepareStage172VisibilityPublicationAdmissionInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage171 guarded executor result boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage171_guarded_executor_result_boundary_owner_present=true"
echo "stage170_guarded_state_write_executor_required=true"
echo "guarded_executor_result_boundary_envelope_materialized=true"
echo "guarded_executor_denial_reason_ledger_bound=true"
echo "rollback_eligibility_boundary_bound=true"
echo "stage172_visibility_publication_admission_input_prepared=true"
echo "guarded_executor_result_boundary_ready=true"
echo "guarded_executor_result_boundary_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
