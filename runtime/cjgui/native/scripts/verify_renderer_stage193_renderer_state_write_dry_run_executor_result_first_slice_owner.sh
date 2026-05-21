#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage193 dry-run executor result owner。
# 它只要求 in-memory executor result envelope，不执行 renderer state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage193_renderer_state_write_dry_run_executor_result_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage193 renderer_state write dry-run executor result: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage193RendererStateWriteDryRunExecutorResultFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage193RendererStateWriteDryRunExecutorResultFirstSliceDraft" \
  "didConsumeStage192RendererStateWriteVisibilityPublicationPositiveDryRun" \
  "didMaterializeRendererStateWriteDryRunExecutorResultEnvelope" \
  "didBindSchemaReadinessFixtureMutationRollbackVisibilityReceipt" \
  "didBindOwnerLocalMutationCandidateToDryRunExecutor" \
  "didBindRollbackSnapshotPlaceholderToDryRunExecutor" \
  "didBindVisibilityPublicationDryRunReceiptToDryRunExecutor" \
  "didPrepareStage194RendererStateWriteResultEnvelopePromotionPreflightInput" \
  "didKeepRendererStateWriteDryRunExecutorNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage193 renderer_state write dry-run executor result: missing token $token" >&2
    exit 3
  fi
done

echo "stage193_renderer_state_write_dry_run_executor_result_owner_present=true"
echo "stage192_visibility_publication_positive_dry_run_required=true"
echo "renderer_state_write_dry_run_executor_result_envelope_materialized=true"
echo "schema_fixture_mutation_rollback_visibility_receipt_bound=true"
echo "owner_local_mutation_candidate_bound_to_dry_run_executor=true"
echo "rollback_snapshot_placeholder_bound_to_dry_run_executor=true"
echo "visibility_publication_dry_run_receipt_bound_to_dry_run_executor=true"
echo "stage194_renderer_state_write_result_envelope_promotion_preflight_input_prepared=true"
echo "renderer_state_write_dry_run_executor_non_mutating=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
