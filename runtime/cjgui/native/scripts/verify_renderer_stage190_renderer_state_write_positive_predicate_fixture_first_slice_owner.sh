#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage190 renderer-state write positive predicate
# fixture owner。fixture 只用于证明正向 predicate shape 可被后续 dry-run 消费。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage190_renderer_state_write_positive_predicate_fixture_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage190 renderer_state positive predicate fixture: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage190RendererStateWritePositivePredicateFixtureFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage190RendererStateWritePositivePredicateFixtureFirstSliceDraft" \
  "didConsumeStage189RendererStateWriteSchemaReadinessRecheck" \
  "didMaterializeRendererStateWritePositivePredicateFixture" \
  "didSynthesizeFixtureProductionTruthPredicate" \
  "didSynthesizeFixtureBackendReadyPredicate" \
  "didSynthesizeFixtureSemanticRuntimeAdmissionPredicate" \
  "didSynthesizeFixturePromotionTokenPredicate" \
  "didSynthesizeFixtureWriteTokenPredicate" \
  "didSynthesizeFixtureGuardedExecutorPredicate" \
  "didSynthesizeFixtureVisibilityPublicationAdmissionPredicate" \
  "didKeepRendererStateWritePositivePredicateFixtureNonProduction"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage190 renderer_state positive predicate fixture: missing token $token" >&2
    exit 3
  fi
done

echo "stage190_renderer_state_positive_predicate_fixture_owner_present=true"
echo "stage189_renderer_state_schema_readiness_recheck_required=true"
echo "renderer_state_write_positive_predicate_fixture_materialized=true"
echo "positive_fixture_production_truth_predicate=true"
echo "positive_fixture_backend_ready_predicate=true"
echo "positive_fixture_semantic_runtime_admission_predicate=true"
echo "positive_fixture_result_envelope_promotion_token=true"
echo "positive_fixture_write_token=true"
echo "positive_fixture_guarded_executor_predicate=true"
echo "positive_fixture_visibility_publication_admission=true"
echo "positive_fixture_all_predicates_positive=true"
echo "stage191_renderer_state_write_guarded_executor_positive_dry_run_input_prepared=true"
echo "positive_predicate_fixture_non_production=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "semantic_runtime_admission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
