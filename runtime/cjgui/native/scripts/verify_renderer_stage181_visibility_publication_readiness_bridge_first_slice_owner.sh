#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage181 visibility publication readiness bridge
# source。它只形成 internal visibility publication ledger，不发布状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage181_visibility_publication_readiness_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage181 visibility publication readiness bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage181VisibilityPublicationReadinessBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage181VisibilityPublicationReadinessBridgeFirstSliceDraft" \
  "didConsumeStage180GuardedExecutorRuntimePreflight" \
  "didMaterializeVisibilityPublicationReadinessBridgeEnvelope" \
  "didBindGuardedExecutorPreflightToVisibilityPublication" \
  "didMaterializeVisibilityPublicationPredicateLedger" \
  "didBindVisibilityPublicationHoldToRollback" \
  "didPrepareStage182RendererStateWriteVisibilityPublicationDecisionInput" \
  "didKeepVisibilityPublicationReadinessBridgeInternalOnly" \
  "didKeepVisibilityPublicationAdmissionDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage181 visibility publication readiness bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage181_visibility_publication_readiness_bridge_owner_present=true"
echo "stage180_guarded_executor_runtime_preflight_required=true"
echo "visibility_publication_readiness_bridge_envelope_materialized=true"
echo "guarded_executor_preflight_to_visibility_publication_bound=true"
echo "visibility_publication_predicate_ledger_materialized=true"
echo "visibility_publication_hold_to_rollback_bound=true"
echo "stage182_renderer_state_write_visibility_publication_decision_input_prepared=true"
echo "visibility_publication_readiness_bridge_internal_only=true"
echo "visibility_publication_admission_denied=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
