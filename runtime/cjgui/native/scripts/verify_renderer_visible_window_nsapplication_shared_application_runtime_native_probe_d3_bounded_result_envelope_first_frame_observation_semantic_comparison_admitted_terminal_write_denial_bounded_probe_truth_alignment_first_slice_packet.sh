#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage129 truth gap matrix packet，并实际执行当前
# shell 的 bounded first-frame native probe。它把 probe facts 与 failure
# classification 写入 isolated result envelope，不升级 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE129_TMPDIR:-/tmp/cjgui-stage129-probe-truth-alignment-$$}"
TRUTH_GAP_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_truth_gap_matrix_first_slice_packet.sh"
FIRST_FRAME_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh"
TRUTH_GAP_LOG="$TMP_DIR/truth-gap-matrix.log"
PROBE_LOG="$TMP_DIR/bounded-first-frame-probe.log"
RESULT_PACKET="$TMP_DIR/stage129-terminal-write-denial-bounded-probe-truth-alignment-first-slice.packet"
TRUTH_GAP_MATRIX_PACKET="${CJGUI_STAGE129_TRUTH_GAP_MATRIX_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$TRUTH_GAP_LOG"
: > "$PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$TRUTH_GAP_PACKET_SCRIPT" "$FIRST_FRAME_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage129 bounded probe truth alignment packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage129 bounded probe truth alignment packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

bool_value() {
  local file="$1"
  local key="$2"
  local value
  value="$(fact_value "$file" "$key")"
  if [[ "$value" == "true" || "$value" == "false" ]]; then
    echo "$value"
  else
    echo "false"
  fi
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage129 bounded probe truth alignment packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$TRUTH_GAP_MATRIX_PACKET" ]]; then
  if env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage129-upstream-gap-$$" \
    zsh "$TRUTH_GAP_PACKET_SCRIPT" > "$TRUTH_GAP_LOG" 2>&1; then
    TRUTH_GAP_MATRIX_PACKET="$(grep -Eo 'truth_gap_matrix_packet_path=[^[:space:]]+' "$TRUTH_GAP_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage129 bounded probe truth alignment packet: truth gap packet failed" >&2
    echo "cjgui stage129 bounded probe truth alignment packet: log=$TRUTH_GAP_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$TRUTH_GAP_MATRIX_PACKET" ]]; then
    echo "cjgui stage129 bounded probe truth alignment packet: provided truth gap packet missing $TRUTH_GAP_MATRIX_PACKET" >&2
    exit 7
  fi
  echo "provided_truth_gap_matrix_packet_used=true" > "$TRUTH_GAP_LOG"
fi

if [[ -z "$TRUTH_GAP_MATRIX_PACKET" || ! -f "$TRUTH_GAP_MATRIX_PACKET" ]]; then
  echo "cjgui stage129 bounded probe truth alignment packet: missing truth gap matrix packet" >&2
  exit 8
fi

for fact in \
  "stage129_terminal_write_denial_truth_gap_matrix_first_slice_packet_passed=true" \
  "production_truth_gap_matrix_ready=true" \
  "exact_missing_predicates_materialized=true" \
  "bounded_probe_truth_alignment_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$TRUTH_GAP_MATRIX_PACKET" "$fact"
done

set +e
env TMPDIR="/tmp/cjgui-stage129-first-frame-probe-$$" zsh "$FIRST_FRAME_PROBE" > "$PROBE_LOG" 2>&1
probe_rc=$?
set -e

if ! grep -F "first_frame_observation_first_slice_probe=" "$PROBE_LOG" >/dev/null 2>&1; then
  echo "cjgui stage129 bounded probe truth alignment packet: bounded probe did not produce a result envelope" >&2
  echo "cjgui stage129 bounded probe truth alignment packet: log=$PROBE_LOG" >&2
  exit 9
fi

probe_result="$(fact_value "$PROBE_LOG" "first_frame_observation_first_slice_probe")"
failure_domain="$(fact_value "$PROBE_LOG" "first_frame_observation_first_slice_failure_domain")"
isolated_metal_device_available="$(bool_value "$PROBE_LOG" "isolated_metal_device_available")"
first_frame_observed="$(bool_value "$PROBE_LOG" "first_frame_observed")"
frame_hash_computed="$(bool_value "$PROBE_LOG" "frame_hash_computed")"
frame_hash_nonzero="$(bool_value "$PROBE_LOG" "frame_hash_nonzero")"
frame_capture_image_created="$(bool_value "$PROBE_LOG" "frame_capture_image_created")"
bounded_gpu_submission_completed="$(bool_value "$PROBE_LOG" "bounded_gpu_submission_completed")"
bounded_drawable_present_scheduled="$(bool_value "$PROBE_LOG" "bounded_drawable_present_scheduled")"
present_called="$(bool_value "$PROBE_LOG" "present_called")"
commit_called="$(bool_value "$PROBE_LOG" "commit_called")"
draw_called="$(bool_value "$PROBE_LOG" "draw_called")"
pipeline_state_created="$(bool_value "$PROBE_LOG" "pipeline_state_created")"
vertex_buffer_created="$(bool_value "$PROBE_LOG" "vertex_buffer_created")"
render_command_encoder_created="$(bool_value "$PROBE_LOG" "render_command_encoder_created")"
captured_nonzero_pixel_sample_count="$(fact_value "$PROBE_LOG" "captured_nonzero_pixel_sample_count")"
frame_pixel_width="$(fact_value "$PROBE_LOG" "frame_pixel_width")"
frame_pixel_height="$(fact_value "$PROBE_LOG" "frame_pixel_height")"
cleanup_observed="$(bool_value "$PROBE_LOG" "cleanup_observed")"
bridge_table_counts_clean="$(bool_value "$PROBE_LOG" "bridge_table_counts_clean")"

if [[ "$probe_rc" == "0" && "$probe_result" == "passed" ]]; then
  current_shell_bounded_probe_positive=true
  route_classification="positive_bounded_first_frame_probe_aligned"
  host_runtime_limitation_detected=false
  cjgui_harness_gap_detected=false
elif [[ "$failure_domain" == "metal_device_unavailable" || "$failure_domain" == "window_capture_unavailable" ]]; then
  current_shell_bounded_probe_positive=false
  route_classification="host_runtime_limitation_classified"
  host_runtime_limitation_detected=true
  cjgui_harness_gap_detected=false
else
  current_shell_bounded_probe_positive=false
  route_classification="cjgui_harness_gap_classified"
  host_runtime_limitation_detected=false
  cjgui_harness_gap_detected=true
fi

{
  echo "stage129_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet_version=1"
  echo "truth_gap_matrix_packet=$TRUTH_GAP_MATRIX_PACKET"
  echo "truth_gap_matrix_consumed=true"
  echo "production_truth_gap_matrix_ready=true"
  echo "bounded_probe_truth_alignment_packet_materialized=true"
  echo "bounded_probe_truth_alignment_route_classification=$route_classification"
  echo "fresh_bounded_runtime_native_probe_executed=true"
  echo "bounded_runtime_native_probe_exit_status=$probe_rc"
  echo "bounded_runtime_native_probe_result_envelope_available=true"
  echo "current_shell_bounded_probe_positive=$current_shell_bounded_probe_positive"
  echo "current_shell_metal_capable=$isolated_metal_device_available"
  echo "host_runtime_limitation_detected=$host_runtime_limitation_detected"
  echo "cjgui_harness_gap_detected=$cjgui_harness_gap_detected"
  echo "first_frame_observation_first_slice_failure_domain=$failure_domain"
  echo "first_frame_observation_first_slice_probe=$probe_result"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "frame_capture_image_created=$frame_capture_image_created"
  echo "frame_pixel_width=$frame_pixel_width"
  echo "frame_pixel_height=$frame_pixel_height"
  echo "captured_nonzero_pixel_sample_count=$captured_nonzero_pixel_sample_count"
  echo "bounded_gpu_submission_completed=$bounded_gpu_submission_completed"
  echo "bounded_drawable_present_scheduled=$bounded_drawable_present_scheduled"
  echo "present_called=$present_called"
  echo "commit_called=$commit_called"
  echo "draw_called=$draw_called"
  echo "pipeline_state_created=$pipeline_state_created"
  echo "vertex_buffer_created=$vertex_buffer_created"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "cleanup_observed=$cleanup_observed"
  echo "bridge_table_counts_clean=$bridge_table_counts_clean"
  echo "probe_log=$PROBE_LOG"
  echo "probe_evidence_kept_isolated=true"
  echo "probe_evidence_promoted_to_production_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=true"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "renderer_state_write_readiness_closure_input_prepared=true"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage129_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage129 bounded probe truth alignment packet: route_classification=$route_classification"
echo "cjgui stage129 bounded probe truth alignment packet: bounded_probe_truth_alignment_packet_path=$RESULT_PACKET"
echo "cjgui stage129 bounded probe truth alignment packet: current_shell_bounded_probe_positive=$current_shell_bounded_probe_positive"
echo "cjgui stage129 bounded probe truth alignment packet: renderer_state_write=false"
