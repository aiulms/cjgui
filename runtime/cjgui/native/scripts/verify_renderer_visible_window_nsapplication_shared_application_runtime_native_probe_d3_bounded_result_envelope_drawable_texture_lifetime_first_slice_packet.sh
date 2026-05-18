#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage108 drawable texture lifetime first-slice packet。
# 它消费 stage107 readiness packet；只有当前 shell 已 admitted command queue /
# command buffer first slice 且 Metal device 可用时，才执行 bounded nextDrawable
# probe。否则只输出 failure classification，不把宿主限制当成 CJGUI harness gap。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage108-drawable-texture-lifetime-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_owner.sh"
STAGE107_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet.sh"
DRAWABLE_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_drawable_texture_lifetime_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE107_LOG="$TMP_DIR/stage107.log"
DRAWABLE_PROBE_LOG="$TMP_DIR/drawable-texture-lifetime-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-drawable-texture-lifetime-first-slice.packet"
STAGE107_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_RENDER_PASS_COLOR_ATTACHMENT_READINESS_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage107" "$TMP_DIR/drawable-probe"
: > "$OWNER_LOG"
: > "$STAGE107_LOG"
: > "$DRAWABLE_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE107_PACKET_SCRIPT" "$DRAWABLE_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_owner_present=true" \
  "bounded_isolated_drawable_acquisition_probe_required=true" \
  "probe_local_drawable_token_lifetime_required=true" \
  "drawable_texture_observation_before_color_attachment_required=true" \
  "color_attachment_configuration_blocked=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage107_input_mode="generated_stage107_packet"
if [[ -n "$STAGE107_PACKET" ]]; then
  if [[ ! -f "$STAGE107_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: provided stage107 packet missing $STAGE107_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage107_packet_used=true"
    echo "stage107_packet_path=$STAGE107_PACKET"
  } > "$STAGE107_LOG"
  stage107_input_mode="provided_stage107_packet"
else
  if ! env TMPDIR="$TMP_DIR/stage107" zsh "$STAGE107_PACKET_SCRIPT" > "$STAGE107_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: stage107 packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: log=$STAGE107_LOG" >&2
    exit 8
  fi
  STAGE107_PACKET="$(grep -Eo 'readiness_packet_path=[^[:space:]]+' "$STAGE107_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE107_PACKET" || ! -f "$STAGE107_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: missing stage107 readiness packet" >&2
  exit 9
fi

for fact in \
  "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_passed=true" \
  "drawable_render_pass_color_attachment_readiness_envelope_ready=true" \
  "color_attachment_configured=false" \
  "encoder_created=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false"; do
  require_file_fact "$STAGE107_PACKET" "$fact"
done

isolated_metal_device_available="$(fact_value "$STAGE107_PACKET" "isolated_metal_device_available")"
current_shell_first_slice_admitted="$(fact_value "$STAGE107_PACKET" "current_shell_first_slice_admitted")"
first_slice_failure_classification="$(fact_value "$STAGE107_PACKET" "first_slice_failure_classification")"
drawable_render_pass_failure_classification="$(fact_value "$STAGE107_PACKET" "drawable_color_attachment_failure_classification")"

bounded_drawable_texture_lifetime_first_slice_should_execute="false"
bounded_drawable_texture_lifetime_first_slice_executed="false"
current_shell_drawable_texture_lifetime_first_slice_ready="false"
drawable_acquired="false"
probe_local_drawable_token_issued="false"
probe_local_drawable_token_released="false"
drawable_texture_observed="false"
drawable_texture_width="0"
drawable_texture_height="0"
next_drawable_called="false"
drawable_texture_lifetime_failure_classification="blocked_pending_first_slice_admission"
drawable_texture_lifetime_failure_domain="first_slice_not_admitted"
drawable_probe_exit_code="not_run"

if [[ "$isolated_metal_device_available" == "false" &&
      "$first_slice_failure_classification" == "host_metal_device_unavailable" ]]; then
  drawable_texture_lifetime_failure_classification="host_metal_device_unavailable"
  drawable_texture_lifetime_failure_domain="metal_device_unavailable"
elif [[ "$current_shell_first_slice_admitted" == "true" &&
        "$isolated_metal_device_available" == "true" ]]; then
  bounded_drawable_texture_lifetime_first_slice_should_execute="true"
fi

if [[ "$bounded_drawable_texture_lifetime_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/drawable-probe" zsh "$DRAWABLE_PROBE" > "$DRAWABLE_PROBE_LOG" 2>&1
  drawable_probe_exit_code="$?"
  set -e
  if [[ "$drawable_probe_exit_code" == "0" ]]; then
    require_file_fact "$DRAWABLE_PROBE_LOG" "bounded_drawable_texture_lifetime_first_slice_probe=passed"
    bounded_drawable_texture_lifetime_first_slice_executed="true"
    current_shell_drawable_texture_lifetime_first_slice_ready="true"
    drawable_texture_lifetime_failure_classification="none"
    drawable_texture_lifetime_failure_domain="none"
    drawable_acquired="$(fact_value "$DRAWABLE_PROBE_LOG" "drawable_acquired")"
    probe_local_drawable_token_issued="$(fact_value "$DRAWABLE_PROBE_LOG" "probe_local_drawable_token_issued")"
    probe_local_drawable_token_released="$(fact_value "$DRAWABLE_PROBE_LOG" "probe_local_drawable_token_released")"
    drawable_texture_observed="$(fact_value "$DRAWABLE_PROBE_LOG" "drawable_texture_observed")"
    drawable_texture_width="$(fact_value "$DRAWABLE_PROBE_LOG" "drawable_texture_width")"
    drawable_texture_height="$(fact_value "$DRAWABLE_PROBE_LOG" "drawable_texture_height")"
    next_drawable_called="$(fact_value "$DRAWABLE_PROBE_LOG" "next_drawable_called")"
  elif [[ "$drawable_probe_exit_code" == "20" &&
          "$(fact_value "$DRAWABLE_PROBE_LOG" "drawable_texture_lifetime_failure_domain")" == "metal_device_unavailable" ]]; then
    drawable_texture_lifetime_failure_classification="host_metal_device_unavailable"
    drawable_texture_lifetime_failure_domain="metal_device_unavailable"
    next_drawable_called="$(fact_value "$DRAWABLE_PROBE_LOG" "next_drawable_called")"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: drawable probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: exit=$drawable_probe_exit_code log=$DRAWABLE_PROBE_LOG" >&2
    exit 10
  fi
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: protected path modified" >&2
  exit 11
fi

{
  echo "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet_version=1"
  echo "stage107_input_mode=$stage107_input_mode"
  echo "stage107_packet=$STAGE107_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage107_log=$STAGE107_LOG"
  echo "drawable_probe_log=$DRAWABLE_PROBE_LOG"
  echo "drawable_probe_exit_code=$drawable_probe_exit_code"
  echo "drawable_render_pass_color_attachment_readiness_envelope_ready=true"
  echo "drawable_texture_lifetime_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  echo "stage107_drawable_render_pass_failure_classification=$drawable_render_pass_failure_classification"
  echo "bounded_drawable_texture_lifetime_first_slice_should_execute=$bounded_drawable_texture_lifetime_first_slice_should_execute"
  echo "bounded_drawable_texture_lifetime_first_slice_executed=$bounded_drawable_texture_lifetime_first_slice_executed"
  echo "current_shell_drawable_texture_lifetime_first_slice_ready=$current_shell_drawable_texture_lifetime_first_slice_ready"
  echo "drawable_acquired=$drawable_acquired"
  echo "probe_local_drawable_token_issued=$probe_local_drawable_token_issued"
  echo "probe_local_drawable_token_released=$probe_local_drawable_token_released"
  echo "drawable_texture_observed=$drawable_texture_observed"
  echo "drawable_texture_width=$drawable_texture_width"
  echo "drawable_texture_height=$drawable_texture_height"
  echo "drawable_texture_lifetime_failure_classification=$drawable_texture_lifetime_failure_classification"
  echo "drawable_texture_lifetime_failure_domain=$drawable_texture_lifetime_failure_domain"
  echo "first_slice_admission_before_drawable_acquisition_required=true"
  echo "probe_local_drawable_token_lifetime_required=true"
  echo "drawable_texture_observation_before_color_attachment_required=true"
  echo "descriptor_drawable_layer_device_cleanup_coownership_required=true"
  echo "production_drawable_texture_lifetime=false"
  echo "production_drawable_acquire_callable=false"
  echo "current_shell_color_attachment_native_execution_ready=false"
  echo "color_attachment_configured=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "next_drawable_called=$next_drawable_called"
  echo "runtime_native_probe_execution=$bounded_drawable_texture_lifetime_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: route_classification=d3_bounded_result_envelope_drawable_texture_lifetime_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: drawable_texture_lifetime_failure_classification=$drawable_texture_lifetime_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable texture lifetime first slice packet: renderer_state_write=false"
