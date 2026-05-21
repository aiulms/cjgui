#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage190 positive predicate fixture packet，
# 消费 stage189 schema-readiness recheck suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE190_PACKET_TMPDIR:-/tmp/cjgui-stage190-renderer-state-positive-predicate-fixture-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage190_renderer_state_write_positive_predicate_fixture_first_slice_owner.sh"
STAGE189_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE189_LOG="$TMP_DIR/stage189.log"
RESULT_PACKET="$TMP_DIR/stage190-renderer-state-write-positive-predicate-fixture-first-slice.packet"
STAGE189_SUITE_PACKET="${CJGUI_STAGE189_RENDERER_STATE_WRITE_SCHEMA_READINESS_RECHECK_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage189"
: > "$OWNER_LOG"
: > "$STAGE189_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE189_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage190 renderer_state positive predicate fixture packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage190 renderer_state positive predicate fixture packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage190 renderer_state positive predicate fixture packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage190 renderer_state positive predicate fixture packet: owner probe failed" >&2
  echo "cjgui stage190 renderer_state positive predicate fixture packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage190_renderer_state_positive_predicate_fixture_owner_present=true" \
  "stage189_renderer_state_schema_readiness_recheck_required=true" \
  "renderer_state_write_positive_predicate_fixture_materialized=true" \
  "positive_fixture_production_truth_predicate=true" \
  "positive_fixture_backend_ready_predicate=true" \
  "positive_fixture_semantic_runtime_admission_predicate=true" \
  "positive_fixture_result_envelope_promotion_token=true" \
  "positive_fixture_write_token=true" \
  "positive_fixture_guarded_executor_predicate=true" \
  "positive_fixture_visibility_publication_admission=true" \
  "positive_fixture_all_predicates_positive=true" \
  "stage191_renderer_state_write_guarded_executor_positive_dry_run_input_prepared=true" \
  "positive_predicate_fixture_non_production=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage189_input_mode="generated_stage189_suite_packet"
if [[ -n "$STAGE189_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE189_SUITE_PACKET" ]]; then
    echo "cjgui stage190 renderer_state positive predicate fixture packet: provided stage189 suite packet missing $STAGE189_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage189_suite_packet_used=true" > "$STAGE189_LOG"
  stage189_input_mode="provided_stage189_suite_packet"
else
  if ! env CJGUI_STAGE189_TMPDIR="$TMP_DIR/stage189" zsh "$STAGE189_SUITE_SCRIPT" > "$STAGE189_LOG" 2>&1; then
    echo "cjgui stage190 renderer_state positive predicate fixture packet: stage189 suite failed" >&2
    echo "cjgui stage190 renderer_state positive predicate fixture packet: log=$STAGE189_LOG" >&2
    exit 8
  fi
  STAGE189_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE189_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE189_SUITE_PACKET" || ! -f "$STAGE189_SUITE_PACKET" ]]; then
  echo "cjgui stage190 renderer_state positive predicate fixture packet: missing stage189 suite packet" >&2
  exit 9
fi
for fact in \
  "stage189_renderer_state_schema_readiness_recheck_suite_passed=true" \
  "renderer_state_write_schema_readiness_recheck_ready=true" \
  "renderer_state_write_schema_readiness_ledger_materialized=true" \
  "renderer_state_write_missing_predicate_ledger_materialized=true" \
  "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "write_token=false" \
  "guarded_executor_predicates_satisfied=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE189_SUITE_PACKET" "$fact"
done

stage189_route="$(fact_value "$STAGE189_SUITE_PACKET" "renderer_state_write_schema_readiness_recheck_route_classification")"
stage190_route="renderer_state_write_positive_predicate_fixture_ready_fixture_only_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage190 renderer_state positive predicate fixture packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage190_renderer_state_write_positive_predicate_fixture_packet_version=1"
  echo "stage189_input_mode=$stage189_input_mode"
  echo "stage189_suite_packet=$STAGE189_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage189_log=$STAGE189_LOG"
  echo "stage189_renderer_state_schema_readiness_recheck_consumed=true"
  echo "stage189_renderer_state_schema_readiness_recheck_route_classification=$stage189_route"
  echo "renderer_state_write_positive_predicate_fixture_route_classification=$stage190_route"
  echo "renderer_state_write_positive_predicate_fixture_ready=true"
  echo "renderer_state_write_positive_predicate_fixture_source_ready=true"
  echo "renderer_state_write_positive_predicate_fixture_runtime_admitted=false"
  echo "renderer_state_write_positive_predicate_fixture_materialized=true"
  echo "positive_fixture_production_truth_predicate=true"
  echo "positive_fixture_backend_ready_predicate=true"
  echo "positive_fixture_semantic_runtime_admission_predicate=true"
  echo "positive_fixture_result_envelope_promotion_token=true"
  echo "positive_fixture_write_token=true"
  echo "positive_fixture_guarded_executor_predicate=true"
  echo "positive_fixture_visibility_publication_admission=true"
  echo "positive_fixture_all_predicates_positive=true"
  echo "positive_predicate_fixture_non_production=true"
  echo "stage191_renderer_state_write_guarded_executor_positive_dry_run_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "write_token=false"
  echo "guarded_executor_predicates_satisfied=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write_eligibility=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage191_renderer_state_write_guarded_executor_positive_dry_run_after_fixture"
  echo "stage190_renderer_state_positive_predicate_fixture_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage190 renderer_state positive predicate fixture packet: route_classification=$stage190_route"
echo "cjgui stage190 renderer_state positive predicate fixture packet: positive_predicate_fixture_packet_path=$RESULT_PACKET"
echo "cjgui stage190 renderer_state positive predicate fixture packet: runtime_state_write=false"
