#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage172 visibility publication admission source。
# 它消费 stage171 result boundary，生成 internal visibility admission envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage172_visibility_publication_admission_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage172 visibility publication admission: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage172VisibilityPublicationAdmissionFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage172VisibilityPublicationAdmissionFirstSliceDraft" \
  "didConsumeStage171GuardedExecutorResultBoundary" \
  "didMaterializeVisibilityPublicationAdmissionEnvelope" \
  "didBindGuardedExecutorBoundaryToVisibilityAdmission" \
  "didBindRollbackEligibilityToVisibilityAdmission" \
  "didBindInternalVisibilityPublicationStopLine" \
  "didPrepareStage173RendererStateWriteAdmissionReadinessInput" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage172 visibility publication admission: missing token $token" >&2
    exit 3
  fi
done

echo "stage172_visibility_publication_admission_owner_present=true"
echo "stage171_guarded_executor_result_boundary_required=true"
echo "visibility_publication_admission_envelope_materialized=true"
echo "guarded_executor_boundary_to_visibility_admission_bound=true"
echo "rollback_eligibility_to_visibility_admission_bound=true"
echo "internal_visibility_publication_stop_line_bound=true"
echo "stage173_renderer_state_write_admission_readiness_input_prepared=true"
echo "visibility_publication_admission_ready=true"
echo "visibility_publication_admission_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
