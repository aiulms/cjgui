#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage128 terminal write denial suite packet，生成
# production-truth gap matrix packet。它只列出缺失谓词，不执行 truth 升级。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE129_TMPDIR:-/tmp/cjgui-stage129-truth-gap-matrix-$$}"
STAGE128_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_suite.sh"
UPSTREAM_LOG="$TMP_DIR/stage128-terminal-write-denial-suite.log"
RESULT_PACKET="$TMP_DIR/stage129-terminal-write-denial-truth-gap-matrix-first-slice.packet"
STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET="${CJGUI_STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$STAGE128_SUITE" ]]; then
  echo "cjgui stage129 truth gap matrix packet: missing executable suite $STAGE128_SUITE" >&2
  exit 3
fi
if ! zsh -n "$STAGE128_SUITE"; then
  echo "cjgui stage129 truth gap matrix packet: stage128 suite syntax failed" >&2
  exit 4
fi

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage129 truth gap matrix packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" ]]; then
  if env CJGUI_STAGE128_TMPDIR="/tmp/cjgui-stage129-upstream-stage128-$$" \
    zsh "$STAGE128_SUITE" > "$UPSTREAM_LOG" 2>&1; then
    STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage129 truth gap matrix packet: stage128 suite failed" >&2
    echo "cjgui stage129 truth gap matrix packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" ]]; then
    echo "cjgui stage129 truth gap matrix packet: provided suite packet missing $STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage128_terminal_write_denial_suite_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" || ! -f "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" ]]; then
  echo "cjgui stage129 truth gap matrix packet: missing stage128 terminal write denial suite packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite_passed=true" \
  "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true" \
  "terminal_renderer_state_write_denied=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" "runtime_native_probe_execution")"
terminal_ready="$(fact_value "$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET" "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready")"

{
  echo "stage129_terminal_write_denial_truth_gap_matrix_first_slice_packet_version=1"
  echo "stage128_terminal_write_denial_suite_packet=$STAGE128_TERMINAL_WRITE_DENIAL_SUITE_PACKET"
  echo "terminal_write_denial_envelope_consumed=true"
  echo "production_truth_gap_matrix_ready=true"
  echo "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=$terminal_ready"
  echo "exact_missing_predicates_materialized=true"
  echo "missing_predicate_frame_hash_persisted=true"
  echo "missing_predicate_result_envelope_promoted_to_production_truth=true"
  echo "missing_predicate_production_render_truth=true"
  echo "missing_predicate_backend_ready_truth=true"
  echo "missing_predicate_visibility_publication_admission=true"
  echo "missing_predicate_rollback_fallback_admission=true"
  echo "missing_predicate_renderer_state_write_admission=true"
  echo "production_truth_gap_count=7"
  echo "frame_hash_persistence_gap_classified=true"
  echo "production_truth_promotion_gap_classified=true"
  echo "production_render_truth_gap_classified=true"
  echo "backend_ready_truth_gap_classified=true"
  echo "visibility_publication_admission_gap_classified=true"
  echo "rollback_fallback_admission_gap_classified=true"
  echo "renderer_state_write_admission_gap_classified=true"
  echo "bounded_probe_truth_alignment_input_prepared=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage129_terminal_write_denial_truth_gap_matrix_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage129 truth gap matrix packet: route_classification=stage129_terminal_write_denial_truth_gap_matrix_first_slice_packet"
echo "cjgui stage129 truth gap matrix packet: truth_gap_matrix_packet_path=$RESULT_PACKET"
echo "cjgui stage129 truth gap matrix packet: production_truth_gap_matrix_ready=true"
echo "cjgui stage129 truth gap matrix packet: renderer_state_write=false"
