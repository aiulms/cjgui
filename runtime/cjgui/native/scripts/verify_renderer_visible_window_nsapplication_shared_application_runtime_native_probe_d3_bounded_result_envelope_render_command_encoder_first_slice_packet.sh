#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage110 render command encoder first-slice packet。
# 它消费 stage109 color attachment suite packet；只有拿到 positive color
# attachment envelope 时，才执行 bounded render command encoder probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage110-render-command-encoder-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_render_command_encoder_first_slice_owner.sh"
STAGE109_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_color_attachment_configuration_first_slice_suite.sh"
ENCODER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_render_command_encoder_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE109_LOG="$TMP_DIR/stage109.log"
ENCODER_PROBE_LOG="$TMP_DIR/render-command-encoder-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-render-command-encoder-first-slice.packet"
STAGE109_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COLOR_ATTACHMENT_CONFIGURATION_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage109" "$TMP_DIR/render-command-encoder-probe"
: > "$OWNER_LOG"
: > "$STAGE109_LOG"
: > "$ENCODER_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE109_SUITE_SCRIPT" "$ENCODER_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_render_command_encoder_first_slice_owner_present=true" \
  "color_attachment_configuration_first_slice_input=true" \
  "positive_color_attachment_envelope_before_encoder_required=true" \
  "bounded_isolated_render_command_encoder_probe_required=true" \
  "probe_local_command_queue_required=true" \
  "probe_local_command_buffer_required=true" \
  "probe_local_render_command_encoder_required=true" \
  "production_encoder_bridge_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage109_input_mode="generated_stage109_suite_packet"
if [[ -n "$STAGE109_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE109_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: provided stage109 suite packet missing $STAGE109_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage109_suite_packet_used=true"
    echo "stage109_suite_packet_path=$STAGE109_SUITE_PACKET"
  } > "$STAGE109_LOG"
  stage109_input_mode="provided_stage109_suite_packet"
else
  if ! env TMPDIR="$TMP_DIR/stage109" zsh "$STAGE109_SUITE_SCRIPT" > "$STAGE109_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: stage109 suite generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: log=$STAGE109_LOG" >&2
    exit 8
  fi
  STAGE109_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE109_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE109_SUITE_PACKET" || ! -f "$STAGE109_SUITE_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: missing stage109 suite packet" >&2
  exit 9
fi

for fact in \
  "d3_bounded_result_envelope_color_attachment_configuration_first_slice_suite_passed=true" \
  "color_attachment_configuration_first_slice_envelope_ready=true" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false"; do
  require_file_fact "$STAGE109_SUITE_PACKET" "$fact"
done

isolated_metal_device_available="$(fact_value "$STAGE109_SUITE_PACKET" "isolated_metal_device_available")"
stage109_color_ready="$(fact_value "$STAGE109_SUITE_PACKET" "current_shell_color_attachment_configuration_first_slice_ready")"
stage109_color_executed="$(fact_value "$STAGE109_SUITE_PACKET" "bounded_color_attachment_configuration_first_slice_executed")"
stage109_failure_classification="$(fact_value "$STAGE109_SUITE_PACKET" "color_attachment_configuration_failure_classification")"
drawable_texture_observed="$(fact_value "$STAGE109_SUITE_PACKET" "drawable_texture_observed")"
render_pass_descriptor_created="$(fact_value "$STAGE109_SUITE_PACKET" "render_pass_descriptor_created")"
color_attachment_configured="$(fact_value "$STAGE109_SUITE_PACKET" "color_attachment_configured")"

bounded_render_command_encoder_first_slice_should_execute="false"
bounded_render_command_encoder_first_slice_executed="false"
current_shell_render_command_encoder_first_slice_ready="false"
render_command_encoder_first_slice_failure_classification="blocked_pending_positive_color_attachment_envelope"
render_command_encoder_first_slice_failure_domain="color_attachment_not_ready"
render_command_encoder_probe_exit_code="not_run"
command_queue_created="false"
command_buffer_created="false"
render_command_encoder_creation_attempted="false"
render_command_encoder_created="false"
end_encoding_called="false"

if [[ "$stage109_color_ready" == "true" &&
      "$stage109_color_executed" == "true" &&
      "$drawable_texture_observed" == "true" &&
      "$render_pass_descriptor_created" == "true" &&
      "$color_attachment_configured" == "true" ]]; then
  bounded_render_command_encoder_first_slice_should_execute="true"
elif [[ "$stage109_failure_classification" == "host_metal_device_unavailable" ]]; then
  render_command_encoder_first_slice_failure_classification="host_metal_device_unavailable"
  render_command_encoder_first_slice_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_render_command_encoder_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/render-command-encoder-probe" zsh "$ENCODER_PROBE" > "$ENCODER_PROBE_LOG" 2>&1
  render_command_encoder_probe_exit_code="$?"
  set -e
  if [[ "$render_command_encoder_probe_exit_code" == "0" ]]; then
    require_file_fact "$ENCODER_PROBE_LOG" "bounded_render_command_encoder_first_slice_probe=passed"
    bounded_render_command_encoder_first_slice_executed="true"
    current_shell_render_command_encoder_first_slice_ready="true"
    render_command_encoder_first_slice_failure_classification="none"
    render_command_encoder_first_slice_failure_domain="none"
    command_queue_created="$(fact_value "$ENCODER_PROBE_LOG" "command_queue_created")"
    command_buffer_created="$(fact_value "$ENCODER_PROBE_LOG" "command_buffer_created")"
    render_command_encoder_creation_attempted="$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_creation_attempted")"
    render_command_encoder_created="$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_created")"
    end_encoding_called="$(fact_value "$ENCODER_PROBE_LOG" "end_encoding_called")"
  elif [[ "$render_command_encoder_probe_exit_code" == "20" &&
          "$(fact_value "$ENCODER_PROBE_LOG" "render_command_encoder_first_slice_failure_domain")" == "metal_device_unavailable" ]]; then
    render_command_encoder_first_slice_failure_classification="host_metal_device_unavailable"
    render_command_encoder_first_slice_failure_domain="metal_device_unavailable"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: render command encoder probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: exit=$render_command_encoder_probe_exit_code log=$ENCODER_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_render_command_encoder_first_slice_ready" == "true" ]]; then
  for fact in \
    "command_queue_created=true" \
    "command_buffer_created=true" \
    "render_command_encoder_created=true" \
    "end_encoding_called=true" \
    "pipeline_state_bound=false" \
    "vertex_buffer_bound=false" \
    "draw_called=false" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "render_executed=false" \
    "renderer_state_write=false"; do
    require_file_fact "$ENCODER_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: protected path modified" >&2
  exit 11
fi

{
  echo "d3_bounded_result_envelope_render_command_encoder_first_slice_packet_version=1"
  echo "stage109_input_mode=$stage109_input_mode"
  echo "stage109_suite_packet=$STAGE109_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage109_log=$STAGE109_LOG"
  echo "render_command_encoder_probe_log=$ENCODER_PROBE_LOG"
  echo "render_command_encoder_probe_exit_code=$render_command_encoder_probe_exit_code"
  echo "color_attachment_configuration_first_slice_envelope_ready=true"
  echo "render_command_encoder_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "stage109_current_shell_color_attachment_configuration_first_slice_ready=$stage109_color_ready"
  echo "stage109_bounded_color_attachment_configuration_first_slice_executed=$stage109_color_executed"
  echo "stage109_color_attachment_configuration_failure_classification=$stage109_failure_classification"
  echo "drawable_texture_observed=$drawable_texture_observed"
  echo "render_pass_descriptor_created=$render_pass_descriptor_created"
  echo "color_attachment_configured=$color_attachment_configured"
  echo "positive_color_attachment_envelope_before_encoder_required=true"
  echo "bounded_render_command_encoder_first_slice_should_execute=$bounded_render_command_encoder_first_slice_should_execute"
  echo "bounded_render_command_encoder_first_slice_executed=$bounded_render_command_encoder_first_slice_executed"
  echo "current_shell_render_command_encoder_first_slice_ready=$current_shell_render_command_encoder_first_slice_ready"
  echo "render_command_encoder_first_slice_failure_classification=$render_command_encoder_first_slice_failure_classification"
  echo "render_command_encoder_first_slice_failure_domain=$render_command_encoder_first_slice_failure_domain"
  echo "command_queue_created=$command_queue_created"
  echo "command_buffer_created=$command_buffer_created"
  echo "render_command_encoder_creation_attempted=$render_command_encoder_creation_attempted"
  echo "render_command_encoder_created=$render_command_encoder_created"
  echo "end_encoding_called=$end_encoding_called"
  echo "probe_local_render_command_encoder_creation=$render_command_encoder_created"
  echo "production_render_command_encoder_creation=false"
  echo "pipeline_state_bound=false"
  echo "vertex_buffer_bound=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$bounded_render_command_encoder_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_render_command_encoder_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: route_classification=d3_bounded_result_envelope_render_command_encoder_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: render_command_encoder_first_slice_failure_classification=$render_command_encoder_first_slice_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded render command encoder first slice packet: renderer_state_write=false"
