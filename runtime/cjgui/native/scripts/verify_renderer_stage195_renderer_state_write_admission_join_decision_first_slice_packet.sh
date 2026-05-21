#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage195 admission join decision packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE195_PACKET_TMPDIR:-/tmp/cjgui-stage195-renderer-state-write-admission-join-decision-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage195_renderer_state_write_admission_join_decision_first_slice_owner.sh"
STAGE194_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage194_renderer_state_write_result_envelope_promotion_preflight_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE194_LOG="$TMP_DIR/stage194.log"
RESULT_PACKET="$TMP_DIR/stage195-renderer-state-write-admission-join-decision-first-slice.packet"
STAGE194_SUITE_PACKET="${CJGUI_STAGE194_RENDERER_STATE_WRITE_RESULT_ENVELOPE_PROMOTION_PREFLIGHT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage194"
: > "$OWNER_LOG"
: > "$STAGE194_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE194_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage195 renderer_state write admission join decision packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage195 renderer_state write admission join decision packet: syntax check failed $script" >&2
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
    echo "cjgui stage195 renderer_state write admission join decision packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage195 renderer_state write admission join decision packet: owner probe failed" >&2
  echo "cjgui stage195 renderer_state write admission join decision packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage195_renderer_state_write_admission_join_decision_owner_present=true" \
  "stage194_result_envelope_promotion_preflight_required=true" \
  "renderer_state_write_admission_join_decision_ledger_materialized=true" \
  "promotion_preflight_bound_to_admission_predicates=true" \
  "positive_fixture_predicates_bound_to_admission_join=true" \
  "production_truth_recheck_request_materialized=true" \
  "semantic_admission_recheck_request_materialized=true" \
  "stage196_renderer_state_write_first_slice_readiness_boundary_input_prepared=true" \
  "renderer_state_write_admission_decision_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage194_input_mode="generated_stage194_suite_packet"
if [[ -n "$STAGE194_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE194_SUITE_PACKET" ]]; then
    echo "cjgui stage195 renderer_state write admission join decision packet: provided stage194 suite packet missing $STAGE194_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage194_suite_packet_used=true" > "$STAGE194_LOG"
  stage194_input_mode="provided_stage194_suite_packet"
else
  if ! env CJGUI_STAGE194_TMPDIR="$TMP_DIR/stage194" zsh "$STAGE194_SUITE_SCRIPT" > "$STAGE194_LOG" 2>&1; then
    echo "cjgui stage195 renderer_state write admission join decision packet: stage194 suite failed" >&2
    echo "cjgui stage195 renderer_state write admission join decision packet: log=$STAGE194_LOG" >&2
    exit 8
  fi
  STAGE194_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE194_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE194_SUITE_PACKET" || ! -f "$STAGE194_SUITE_PACKET" ]]; then
  echo "cjgui stage195 renderer_state write admission join decision packet: missing stage194 suite packet" >&2
  exit 9
fi
for fact in \
  "stage194_renderer_state_write_result_envelope_promotion_preflight_suite_passed=true" \
  "renderer_state_write_result_envelope_promotion_preflight_ready=true" \
  "result_envelope_promotion_token_candidate_ledger_materialized=true" \
  "missing_production_predicate_ledger_materialized=true" \
  "stage195_renderer_state_write_admission_join_decision_input_prepared=true" \
  "result_envelope_promotion_token=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE194_SUITE_PACKET" "$fact"
done

stage194_route="$(fact_value "$STAGE194_SUITE_PACKET" "renderer_state_write_result_envelope_promotion_preflight_route_classification")"
stage195_route="renderer_state_write_admission_join_decision_ready_rechecks_materialized_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage195 renderer_state write admission join decision packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage195_renderer_state_write_admission_join_decision_packet_version=1"
  echo "stage194_input_mode=$stage194_input_mode"
  echo "stage194_suite_packet=$STAGE194_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage194_log=$STAGE194_LOG"
  echo "stage194_result_envelope_promotion_preflight_consumed=true"
  echo "stage194_result_envelope_promotion_preflight_route_classification=$stage194_route"
  echo "renderer_state_write_admission_join_decision_route_classification=$stage195_route"
  echo "renderer_state_write_admission_join_decision_ready=true"
  echo "renderer_state_write_admission_join_decision_source_ready=true"
  echo "renderer_state_write_admission_join_decision_runtime_admitted=false"
  echo "renderer_state_write_admission_join_decision_ledger_materialized=true"
  echo "promotion_preflight_bound_to_admission_predicates=true"
  echo "positive_fixture_predicates_bound_to_admission_join=true"
  echo "production_truth_recheck_request_materialized=true"
  echo "semantic_admission_recheck_request_materialized=true"
  echo "stage196_renderer_state_write_first_slice_readiness_boundary_input_prepared=true"
  echo "renderer_state_write_admission_decision_denied=true"
  echo "renderer_state_write_eligibility=false"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage196_renderer_state_write_first_slice_readiness_boundary_after_admission_join_decision"
  echo "stage195_renderer_state_write_admission_join_decision_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage195 renderer_state write admission join decision packet: route_classification=$stage195_route"
echo "cjgui stage195 renderer_state write admission join decision packet: admission_join_decision_packet_path=$RESULT_PACKET"
echo "cjgui stage195 renderer_state write admission join decision packet: renderer_state_write=false"
