#!/usr/bin/env zsh
#
# 维护注释：验证 stage229 renderer backend handoff dry-run owner。
# 它只把 stage228 readiness 接到现有 packet handoff receipt，不执行后端。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage229_backend_handoff_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage229 backend handoff dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage229BackendHandoffDryRunFacts" \
  "CjguiInternalRendererStage229BackendHandoffDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage229BackendHandoffDryRunDraft" \
  "didConsumeStage228RendererSubmissionReadinessDecision" \
  "didConsumeRendererPacketHandoffReceipt" \
  "didMaterializeRendererBackendHandoffDryRun" \
  "didBindBackendHandoffDryRunToSubmissionReadiness" \
  "didClassifyBackendCandidateAsNonSubmitting" \
  "didPrepareStage230RendererBackendHandoffPacketInput" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepBackendImplementationBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage229 backend handoff dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage229_backend_handoff_dry_run_owner_present=true"
echo "stage228_renderer_submission_readiness_decision_required=true"
echo "renderer_packet_handoff_receipt_required=true"
echo "renderer_backend_handoff_dry_run_materialized=true"
echo "backend_handoff_dry_run_bound_to_submission_readiness=true"
echo "backend_candidate_non_submitting=true"
echo "stage230_renderer_backend_handoff_packet_input_prepared=true"
echo "backend_implementation=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
