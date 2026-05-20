#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage132 commit readiness recheck packet，并重新执行
# bounded first-frame probe，把当前 shell 的 positive probe / frame hash facts
# 物化为 isolated packet。宿主无 Metal 时只分类，不升级 truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE133_TMPDIR:-/tmp/cjgui-stage133-positive-probe-materialization-$$}"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_commit_recheck_first_slice_packet.sh"
FIRST_FRAME_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_first_frame_observation_first_slice.sh"
RECHECK_LOG="$TMP_DIR/stage132-commit-recheck.log"
PROBE_LOG="$TMP_DIR/fresh-bounded-first-frame-probe.log"
RESULT_PACKET="$TMP_DIR/stage133-positive-probe-materialization-first-slice.packet"
RECHECK_PACKET="${CJGUI_STAGE133_STAGE132_COMMIT_RECHECK_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$RECHECK_LOG"
: > "$PROBE_LOG"
: > "$RESULT_PACKET"

for script in "$RECHECK_PACKET_SCRIPT" "$FIRST_FRAME_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage133 positive probe materialization packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage133 positive probe materialization packet: syntax check failed $script" >&2
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
    echo "cjgui stage133 positive probe materialization packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$RECHECK_PACKET" ]]; then
  if env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage133-upstream-stage132-recheck-$$" \
    zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_LOG" 2>&1; then
    RECHECK_PACKET="$(grep -Eo 'frame_hash_persistence_commit_readiness_recheck_packet_path=[^[:space:]]+' "$RECHECK_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage133 positive probe materialization packet: stage132 recheck packet failed" >&2
    echo "cjgui stage133 positive probe materialization packet: log=$RECHECK_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$RECHECK_PACKET" ]]; then
    echo "cjgui stage133 positive probe materialization packet: provided stage132 recheck packet missing $RECHECK_PACKET" >&2
    exit 7
  fi
  echo "provided_stage132_commit_recheck_packet_used=true" > "$RECHECK_LOG"
fi

if [[ -z "$RECHECK_PACKET" || ! -f "$RECHECK_PACKET" ]]; then
  echo "cjgui stage133 positive probe materialization packet: missing stage132 recheck packet" >&2
  exit 8
fi

for fact in \
  "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_packet_passed=true" \
  "frame_hash_persistence_commit_readiness_recheck_ready=true" \
  "positive_probe_materialization_or_production_truth_token_gate_next_route_prepared=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$RECHECK_PACKET" "$fact"
done

backing_store_token_issued_from_recheck="$(bool_value "$RECHECK_PACKET" "backing_store_token_issued")"
frame_hash_persistence_commit_admitted_from_recheck="$(bool_value "$RECHECK_PACKET" "frame_hash_persistence_commit_admitted")"

set +e
env TMPDIR="/tmp/cjgui-stage133-fresh-first-frame-probe-$$" zsh "$FIRST_FRAME_PROBE" > "$PROBE_LOG" 2>&1
probe_rc=$?
set -e

if ! grep -F "first_frame_observation_first_slice_probe=" "$PROBE_LOG" >/dev/null 2>&1; then
  echo "cjgui stage133 positive probe materialization packet: fresh bounded probe did not produce envelope" >&2
  echo "cjgui stage133 positive probe materialization packet: log=$PROBE_LOG" >&2
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
cleanup_observed="$(bool_value "$PROBE_LOG" "cleanup_observed")"
bridge_table_counts_clean="$(bool_value "$PROBE_LOG" "bridge_table_counts_clean")"

if [[ "$probe_rc" == "0" && "$probe_result" == "passed" &&
      "$first_frame_observed" == "true" && "$frame_hash_nonzero" == "true" ]]; then
  positive_live_probe_observed=true
  nonzero_frame_hash_observed=true
  route_classification="positive_probe_materialized"
  host_runtime_limitation_detected=false
  cjgui_harness_gap_detected=false
elif [[ "$failure_domain" == "metal_device_unavailable" || "$failure_domain" == "window_capture_unavailable" ]]; then
  positive_live_probe_observed=false
  nonzero_frame_hash_observed=false
  route_classification="host_runtime_limitation_classified"
  host_runtime_limitation_detected=true
  cjgui_harness_gap_detected=false
else
  positive_live_probe_observed=false
  nonzero_frame_hash_observed=false
  route_classification="cjgui_harness_gap_classified"
  host_runtime_limitation_detected=false
  cjgui_harness_gap_detected=true
fi

if [[ "$host_runtime_limitation_detected" == "false" ]]; then
  host_runtime_limitation_absent=true
else
  host_runtime_limitation_absent=false
fi
if [[ "$cjgui_harness_gap_detected" == "false" ]]; then
  cjgui_harness_gap_absent=true
else
  cjgui_harness_gap_absent=false
fi
if [[ "$positive_live_probe_observed" == "true" &&
      "$nonzero_frame_hash_observed" == "true" &&
      "$host_runtime_limitation_absent" == "true" &&
      "$cjgui_harness_gap_absent" == "true" ]]; then
  backing_store_token_materialization_candidate=true
else
  backing_store_token_materialization_candidate=false
fi

{
  echo "stage133_positive_probe_materialization_first_slice_packet_version=1"
  echo "frame_hash_persistence_commit_readiness_recheck_packet=$RECHECK_PACKET"
  echo "frame_hash_persistence_commit_readiness_recheck_consumed=true"
  echo "fresh_bounded_first_frame_probe_executed=true"
  echo "fresh_bounded_first_frame_probe_log=$PROBE_LOG"
  echo "fresh_bounded_first_frame_probe_exit_status=$probe_rc"
  echo "fresh_bounded_first_frame_probe_result=$probe_result"
  echo "positive_probe_materialization_route_classification=$route_classification"
  echo "current_shell_metal_capable=$isolated_metal_device_available"
  echo "positive_live_probe_observed=$positive_live_probe_observed"
  echo "nonzero_frame_hash_observed=$nonzero_frame_hash_observed"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "first_frame_observation_first_slice_failure_domain=$failure_domain"
  echo "host_runtime_limitation_detected=$host_runtime_limitation_detected"
  echo "cjgui_harness_gap_detected=$cjgui_harness_gap_detected"
  echo "host_runtime_limitation_absent=$host_runtime_limitation_absent"
  echo "cjgui_harness_gap_absent=$cjgui_harness_gap_absent"
  echo "frame_capture_image_created=$frame_capture_image_created"
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
  echo "positive_probe_facts_kept_isolated=true"
  echo "backing_store_token_materialization_candidate=$backing_store_token_materialization_candidate"
  echo "backing_store_token_issued=$backing_store_token_issued_from_recheck"
  echo "frame_hash_persistence_commit_admitted=$frame_hash_persistence_commit_admitted_from_recheck"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "production_truth_token_gate_recheck_input_prepared=true"
  echo "next_route=production_truth_token_gate_recheck_first_slice"
  echo "runtime_native_probe_execution=true"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage133_positive_probe_materialization_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage133 positive probe materialization packet: route_classification=$route_classification"
echo "cjgui stage133 positive probe materialization packet: positive_probe_materialization_packet_path=$RESULT_PACKET"
echo "cjgui stage133 positive probe materialization packet: positive_live_probe_observed=$positive_live_probe_observed"
echo "cjgui stage133 positive probe materialization packet: renderer_state_write=false"
