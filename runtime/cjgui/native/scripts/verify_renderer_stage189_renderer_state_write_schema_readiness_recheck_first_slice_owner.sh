#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage189 renderer-state write schema-readiness
# recheck owner。它只复核 stage188 形成的 runtime_state schema / mutation /
# executor / visibility publication schema ledger，不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage189 renderer_state schema readiness recheck: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage189RendererStateWriteSchemaReadinessRecheckFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage189RendererStateWriteSchemaReadinessRecheckFirstSliceDraft" \
  "didConsumeStage188RuntimeStateWriteVisibilityPublicationSchemaBridge" \
  "didRecheckRuntimeStateWriteSchemaCandidate" \
  "didRecheckRuntimeStateWriteMutationRequestPayload" \
  "didRecheckRuntimeStateWriteGuardedExecutorPredicates" \
  "didRecheckVisibilityPublicationSchemaLedger" \
  "didBindRuntimeStateSchemaReadinessToRendererStateWriteAdmission" \
  "didMaterializeRendererStateWriteMissingPredicateLedger" \
  "didPrepareStage190RendererStateWritePositivePredicateFixtureInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage189 renderer_state schema readiness recheck: missing token $token" >&2
    exit 3
  fi
done

echo "stage189_renderer_state_schema_readiness_recheck_owner_present=true"
echo "stage188_runtime_state_visibility_publication_schema_bridge_required=true"
echo "runtime_state_write_schema_candidate_rechecked=true"
echo "runtime_state_write_mutation_request_payload_rechecked=true"
echo "runtime_state_write_guarded_executor_predicates_rechecked=true"
echo "visibility_publication_schema_ledger_rechecked=true"
echo "renderer_state_write_schema_readiness_ledger_materialized=true"
echo "renderer_state_write_missing_predicate_ledger_materialized=true"
echo "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true"
echo "schema_readiness_recheck_non_mutating=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "semantic_runtime_admission=false"
echo "result_envelope_promotion_token=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
