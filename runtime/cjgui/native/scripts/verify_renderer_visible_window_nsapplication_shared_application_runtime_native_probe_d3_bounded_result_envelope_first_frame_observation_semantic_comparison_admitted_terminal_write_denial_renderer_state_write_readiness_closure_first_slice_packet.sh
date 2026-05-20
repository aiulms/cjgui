#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage129 bounded probe truth alignment packet，
# 汇总 renderer-state write readiness closure。它给出当前 blocked 结论，
# 不执行 mutation 或 runtime_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE129_TMPDIR:-/tmp/cjgui-stage129-write-readiness-$$}"
ALIGNMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet.sh"
ALIGNMENT_LOG="$TMP_DIR/bounded-probe-truth-alignment.log"
RESULT_PACKET="$TMP_DIR/stage129-terminal-write-denial-renderer-state-write-readiness-closure-first-slice.packet"
BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET="${CJGUI_STAGE129_BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ALIGNMENT_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$ALIGNMENT_PACKET_SCRIPT" ]]; then
  echo "cjgui stage129 renderer-state write readiness closure packet: missing executable script $ALIGNMENT_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$ALIGNMENT_PACKET_SCRIPT"; then
  echo "cjgui stage129 renderer-state write readiness closure packet: alignment script syntax failed" >&2
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
    echo "cjgui stage129 renderer-state write readiness closure packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" ]]; then
  if env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage129-upstream-alignment-$$" \
    zsh "$ALIGNMENT_PACKET_SCRIPT" > "$ALIGNMENT_LOG" 2>&1; then
    BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET="$(grep -Eo 'bounded_probe_truth_alignment_packet_path=[^[:space:]]+' "$ALIGNMENT_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage129 renderer-state write readiness closure packet: alignment packet failed" >&2
    echo "cjgui stage129 renderer-state write readiness closure packet: log=$ALIGNMENT_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" ]]; then
    echo "cjgui stage129 renderer-state write readiness closure packet: provided alignment packet missing $BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" >&2
    exit 7
  fi
  echo "provided_bounded_probe_truth_alignment_packet_used=true" > "$ALIGNMENT_LOG"
fi

if [[ -z "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" || ! -f "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" ]]; then
  echo "cjgui stage129 renderer-state write readiness closure packet: missing bounded probe truth alignment packet" >&2
  exit 8
fi

for fact in \
  "stage129_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet_passed=true" \
  "truth_gap_matrix_consumed=true" \
  "bounded_probe_truth_alignment_packet_materialized=true" \
  "fresh_bounded_runtime_native_probe_executed=true" \
  "probe_evidence_kept_isolated=true" \
  "renderer_state_write_readiness_closure_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "$fact"
done

alignment_route="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "bounded_probe_truth_alignment_route_classification")"
probe_positive="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "cjgui_harness_gap_detected")"
failure_domain="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "first_frame_observation_first_slice_failure_domain")"
first_frame_observed="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "first_frame_observed")"
frame_hash_computed="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "frame_hash_nonzero")"
runtime_native_probe_execution="$(fact_value "$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET" "runtime_native_probe_execution")"

if [[ "$probe_positive" == "true" ]]; then
  renderer_state_write_blocked_by_probe_classification=false
else
  renderer_state_write_blocked_by_probe_classification=true
fi

{
  echo "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet_version=1"
  echo "bounded_probe_truth_alignment_packet=$BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET"
  echo "bounded_probe_truth_alignment_consumed=true"
  echo "renderer_state_write_readiness_closure_ready=true"
  echo "renderer_state_write_readiness_closed_without_mutation=true"
  echo "production_truth_gap_matrix_bound_to_write_readiness=true"
  echo "fresh_probe_envelope_bound_to_write_readiness=true"
  echo "failure_classification_bound_to_write_readiness=true"
  echo "bounded_probe_truth_alignment_route_classification=$alignment_route"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "first_frame_observation_first_slice_failure_domain=$failure_domain"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "production_truth_gap_closed=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write_blocked_by_missing_production_truth=true"
  echo "renderer_state_write_blocked_by_frame_hash_persistence_gap=true"
  echo "renderer_state_write_blocked_by_visibility_publication_denial=true"
  echo "renderer_state_write_blocked_by_rollback_fallback_denial=true"
  echo "renderer_state_write_blocked_by_terminal_denial=true"
  echo "renderer_state_write_blocked_by_probe_classification=$renderer_state_write_blocked_by_probe_classification"
  echo "frame_hash_persistence_evidence_next_route_prepared=true"
  echo "next_route=frame_hash_persistence_evidence_envelope_first_slice"
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
  echo "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage129 renderer-state write readiness closure packet: route_classification=stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet"
echo "cjgui stage129 renderer-state write readiness closure packet: write_readiness_closure_packet_path=$RESULT_PACKET"
echo "cjgui stage129 renderer-state write readiness closure packet: renderer_state_write_admission_ready=false"
echo "cjgui stage129 renderer-state write readiness closure packet: renderer_state_write=false"
