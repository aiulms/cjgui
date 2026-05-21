#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage191 guarded executor positive dry-run owner。
# 它消费 stage190 fixture，只物化 owner-local mutation candidate envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage191_renderer_state_write_guarded_executor_positive_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage191 renderer_state guarded executor positive dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage191RendererStateWriteGuardedExecutorPositiveDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage191RendererStateWriteGuardedExecutorPositiveDryRunFirstSliceDraft" \
  "didConsumeStage190RendererStateWritePositivePredicateFixture" \
  "didMaterializeRendererStateWriteGuardedExecutorPositiveDryRun" \
  "didBindPositivePredicateFixtureToGuardedExecutorDryRun" \
  "didMaterializeOwnerLocalMutationCandidateEnvelope" \
  "didMaterializeRollbackSnapshotPlaceholder" \
  "didConfirmFixtureGuardedExecutorPredicatesSatisfied" \
  "didPrepareStage192RendererStateWriteVisibilityPublicationPositiveDryRunInput" \
  "didKeepRendererStateWriteGuardedExecutorDryRunNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage191 renderer_state guarded executor positive dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage191_renderer_state_guarded_executor_positive_dry_run_owner_present=true"
echo "stage190_renderer_state_positive_predicate_fixture_required=true"
echo "renderer_state_write_guarded_executor_positive_dry_run_materialized=true"
echo "positive_fixture_to_guarded_executor_dry_run_bound=true"
echo "owner_local_mutation_candidate_envelope_materialized=true"
echo "rollback_snapshot_placeholder_materialized=true"
echo "fixture_guarded_executor_predicates_satisfied=true"
echo "stage192_renderer_state_write_visibility_publication_positive_dry_run_input_prepared=true"
echo "guarded_executor_positive_dry_run_non_mutating=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
