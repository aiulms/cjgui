#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage189 renderer-state write schema-readiness
# recheck packet，消费 stage188 visibility publication schema bridge suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE189_PACKET_TMPDIR:-/tmp/cjgui-stage189-renderer-state-schema-readiness-recheck-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice_owner.sh"
STAGE188_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage188_runtime_state_write_visibility_publication_schema_bridge_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE188_LOG="$TMP_DIR/stage188.log"
RESULT_PACKET="$TMP_DIR/stage189-renderer-state-write-schema-readiness-recheck-first-slice.packet"
STAGE188_SUITE_PACKET="${CJGUI_STAGE188_RUNTIME_STATE_WRITE_VISIBILITY_PUBLICATION_SCHEMA_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage188"
: > "$OWNER_LOG"
: > "$STAGE188_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE188_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage189 renderer_state schema readiness recheck packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage189 renderer_state schema readiness recheck packet: syntax check failed $script" >&2
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
    echo "cjgui stage189 renderer_state schema readiness recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck packet: owner probe failed" >&2
  echo "cjgui stage189 renderer_state schema readiness recheck packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage189_renderer_state_schema_readiness_recheck_owner_present=true" \
  "stage188_runtime_state_visibility_publication_schema_bridge_required=true" \
  "runtime_state_write_schema_candidate_rechecked=true" \
  "runtime_state_write_mutation_request_payload_rechecked=true" \
  "runtime_state_write_guarded_executor_predicates_rechecked=true" \
  "visibility_publication_schema_ledger_rechecked=true" \
  "renderer_state_write_schema_readiness_ledger_materialized=true" \
  "renderer_state_write_missing_predicate_ledger_materialized=true" \
  "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true" \
  "schema_readiness_recheck_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage188_input_mode="generated_stage188_suite_packet"
if [[ -n "$STAGE188_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE188_SUITE_PACKET" ]]; then
    echo "cjgui stage189 renderer_state schema readiness recheck packet: provided stage188 suite packet missing $STAGE188_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage188_suite_packet_used=true" > "$STAGE188_LOG"
  stage188_input_mode="provided_stage188_suite_packet"
else
  if ! env CJGUI_STAGE188_TMPDIR="$TMP_DIR/stage188" zsh "$STAGE188_SUITE_SCRIPT" > "$STAGE188_LOG" 2>&1; then
    echo "cjgui stage189 renderer_state schema readiness recheck packet: stage188 suite failed" >&2
    echo "cjgui stage189 renderer_state schema readiness recheck packet: log=$STAGE188_LOG" >&2
    exit 8
  fi
  STAGE188_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE188_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE188_SUITE_PACKET" || ! -f "$STAGE188_SUITE_PACKET" ]]; then
  echo "cjgui stage189 renderer_state schema readiness recheck packet: missing stage188 suite packet" >&2
  exit 9
fi
for fact in \
  "stage188_runtime_state_visibility_publication_schema_bridge_suite_passed=true" \
  "runtime_state_write_visibility_publication_schema_bridge_ready=true" \
  "runtime_state_write_visibility_publication_schema_bridge_materialized=true" \
  "guarded_executor_preflight_to_visibility_publication_schema_bound=true" \
  "visibility_publication_schema_predicate_ledger_materialized=true" \
  "visibility_publication_hold_to_schema_bridge_bound=true" \
  "stage189_renderer_state_write_schema_readiness_recheck_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE188_SUITE_PACKET" "$fact"
done

stage188_route="$(fact_value "$STAGE188_SUITE_PACKET" "runtime_state_write_visibility_publication_schema_bridge_route_classification")"
stage189_route="renderer_state_write_schema_readiness_recheck_ready_missing_predicates_materialized"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage189_renderer_state_write_schema_readiness_recheck_packet_version=1"
  echo "stage188_input_mode=$stage188_input_mode"
  echo "stage188_suite_packet=$STAGE188_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage188_log=$STAGE188_LOG"
  echo "stage188_runtime_state_visibility_publication_schema_bridge_consumed=true"
  echo "stage188_runtime_state_visibility_publication_schema_bridge_route_classification=$stage188_route"
  echo "renderer_state_write_schema_readiness_recheck_route_classification=$stage189_route"
  echo "renderer_state_write_schema_readiness_recheck_ready=true"
  echo "renderer_state_write_schema_readiness_recheck_source_ready=true"
  echo "renderer_state_write_schema_readiness_recheck_runtime_admitted=false"
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
  echo "next_route=stage190_renderer_state_write_positive_predicate_fixture_after_schema_readiness_recheck"
  echo "stage189_renderer_state_schema_readiness_recheck_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage189 renderer_state schema readiness recheck packet: route_classification=$stage189_route"
echo "cjgui stage189 renderer_state schema readiness recheck packet: schema_readiness_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage189 renderer_state schema readiness recheck packet: runtime_state_write=false"
