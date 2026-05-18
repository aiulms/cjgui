#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage109 color attachment configuration first-slice
# packet。它消费 stage108 drawable texture lifetime suite packet；只有拿到
# positive drawable texture envelope 时，才执行 bounded color attachment
# configuration probe。否则只输出 failure classification。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage109-color-attachment-configuration-first-slice-packet"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_color_attachment_configuration_first_slice_owner.sh"
STAGE108_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite.sh"
COLOR_ATTACHMENT_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_color_attachment_configuration_first_slice.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE108_LOG="$TMP_DIR/stage108.log"
COLOR_ATTACHMENT_PROBE_LOG="$TMP_DIR/color-attachment-configuration-first-slice.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-color-attachment-configuration-first-slice.packet"
STAGE108_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_DRAWABLE_TEXTURE_LIFETIME_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage108" "$TMP_DIR/color-attachment-probe"
: > "$OWNER_LOG"
: > "$STAGE108_LOG"
: > "$COLOR_ATTACHMENT_PROBE_LOG"
: > "$READINESS_PACKET"

for script in "$OWNER_PROBE" "$STAGE108_SUITE_SCRIPT" "$COLOR_ATTACHMENT_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "d3_bounded_result_envelope_color_attachment_configuration_first_slice_owner_present=true" \
  "drawable_texture_lifetime_first_slice_input=true" \
  "positive_drawable_texture_envelope_before_configuration_required=true" \
  "bounded_isolated_color_attachment_configuration_probe_required=true" \
  "probe_local_render_pass_descriptor_required=true" \
  "probe_local_drawable_texture_binding_required=true" \
  "encoder_creation_blocked_after_color_attachment=true" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage108_input_mode="generated_stage108_suite_packet"
if [[ -n "$STAGE108_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE108_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: provided stage108 suite packet missing $STAGE108_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage108_suite_packet_used=true"
    echo "stage108_suite_packet_path=$STAGE108_SUITE_PACKET"
  } > "$STAGE108_LOG"
  stage108_input_mode="provided_stage108_suite_packet"
else
  if ! env TMPDIR="$TMP_DIR/stage108" zsh "$STAGE108_SUITE_SCRIPT" > "$STAGE108_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: stage108 suite generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: log=$STAGE108_LOG" >&2
    exit 8
  fi
  STAGE108_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE108_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE108_SUITE_PACKET" || ! -f "$STAGE108_SUITE_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: missing stage108 suite packet" >&2
  exit 9
fi

for fact in \
  "d3_bounded_result_envelope_drawable_texture_lifetime_first_slice_suite_passed=true" \
  "drawable_texture_lifetime_first_slice_envelope_ready=true" \
  "color_attachment_configured=false" \
  "encoder_created=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "renderer_state_write=false"; do
  require_file_fact "$STAGE108_SUITE_PACKET" "$fact"
done

isolated_metal_device_available="$(fact_value "$STAGE108_SUITE_PACKET" "isolated_metal_device_available")"
stage108_first_slice_ready="$(fact_value "$STAGE108_SUITE_PACKET" "current_shell_drawable_texture_lifetime_first_slice_ready")"
stage108_bounded_executed="$(fact_value "$STAGE108_SUITE_PACKET" "bounded_drawable_texture_lifetime_first_slice_executed")"
stage108_failure_classification="$(fact_value "$STAGE108_SUITE_PACKET" "drawable_texture_lifetime_failure_classification")"
drawable_acquired="$(fact_value "$STAGE108_SUITE_PACKET" "drawable_acquired")"
drawable_texture_observed="$(fact_value "$STAGE108_SUITE_PACKET" "drawable_texture_observed")"
next_drawable_called="$(fact_value "$STAGE108_SUITE_PACKET" "next_drawable_called")"

bounded_color_attachment_configuration_first_slice_should_execute="false"
bounded_color_attachment_configuration_first_slice_executed="false"
current_shell_color_attachment_configuration_first_slice_ready="false"
color_attachment_configuration_failure_classification="blocked_pending_positive_drawable_texture_lifetime_envelope"
color_attachment_configuration_failure_domain="drawable_texture_lifetime_not_ready"
color_attachment_probe_exit_code="not_run"
render_pass_descriptor_created="false"
color_attachment_slot_observed="false"
color_attachment_configured="false"
attachment_texture_matches_drawable_texture="false"
attachment_load_action_clear="false"
attachment_store_action_store="false"

if [[ "$stage108_first_slice_ready" == "true" &&
      "$stage108_bounded_executed" == "true" &&
      "$drawable_acquired" == "true" &&
      "$drawable_texture_observed" == "true" ]]; then
  bounded_color_attachment_configuration_first_slice_should_execute="true"
elif [[ "$stage108_failure_classification" == "host_metal_device_unavailable" ]]; then
  color_attachment_configuration_failure_classification="host_metal_device_unavailable"
  color_attachment_configuration_failure_domain="metal_device_unavailable"
fi

if [[ "$bounded_color_attachment_configuration_first_slice_should_execute" == "true" ]]; then
  set +e
  env TMPDIR="$TMP_DIR/color-attachment-probe" zsh "$COLOR_ATTACHMENT_PROBE" > "$COLOR_ATTACHMENT_PROBE_LOG" 2>&1
  color_attachment_probe_exit_code="$?"
  set -e
  if [[ "$color_attachment_probe_exit_code" == "0" ]]; then
    require_file_fact "$COLOR_ATTACHMENT_PROBE_LOG" "bounded_color_attachment_configuration_first_slice_probe=passed"
    bounded_color_attachment_configuration_first_slice_executed="true"
    current_shell_color_attachment_configuration_first_slice_ready="true"
    color_attachment_configuration_failure_classification="none"
    color_attachment_configuration_failure_domain="none"
    render_pass_descriptor_created="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "render_pass_descriptor_created")"
    color_attachment_slot_observed="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "color_attachment_slot_observed")"
    color_attachment_configured="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "color_attachment_configured")"
    attachment_texture_matches_drawable_texture="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "attachment_texture_matches_drawable_texture")"
    attachment_load_action_clear="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "attachment_load_action_clear")"
    attachment_store_action_store="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "attachment_store_action_store")"
  elif [[ "$color_attachment_probe_exit_code" == "20" &&
          "$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "color_attachment_configuration_failure_domain")" == "metal_device_unavailable" ]]; then
    color_attachment_configuration_failure_classification="host_metal_device_unavailable"
    color_attachment_configuration_failure_domain="metal_device_unavailable"
    next_drawable_called="$(fact_value "$COLOR_ATTACHMENT_PROBE_LOG" "next_drawable_called")"
  else
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: color attachment probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: exit=$color_attachment_probe_exit_code log=$COLOR_ATTACHMENT_PROBE_LOG" >&2
    exit 10
  fi
fi

if [[ "$current_shell_color_attachment_configuration_first_slice_ready" == "true" ]]; then
  for fact in \
    "color_attachment_configured=true" \
    "encoder_created=false" \
    "draw_called=false" \
    "commit_called=false" \
    "present_called=false" \
    "gpu_work_submitted=false" \
    "render_executed=false" \
    "renderer_state_write=false"; do
    require_file_fact "$COLOR_ATTACHMENT_PROBE_LOG" "$fact"
  done
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: protected path modified" >&2
  exit 11
fi

{
  echo "d3_bounded_result_envelope_color_attachment_configuration_first_slice_packet_version=1"
  echo "stage108_input_mode=$stage108_input_mode"
  echo "stage108_suite_packet=$STAGE108_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage108_log=$STAGE108_LOG"
  echo "color_attachment_probe_log=$COLOR_ATTACHMENT_PROBE_LOG"
  echo "color_attachment_probe_exit_code=$color_attachment_probe_exit_code"
  echo "drawable_texture_lifetime_first_slice_envelope_ready=true"
  echo "color_attachment_configuration_first_slice_owner_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "stage108_current_shell_drawable_texture_lifetime_first_slice_ready=$stage108_first_slice_ready"
  echo "stage108_bounded_drawable_texture_lifetime_first_slice_executed=$stage108_bounded_executed"
  echo "stage108_drawable_texture_lifetime_failure_classification=$stage108_failure_classification"
  echo "next_drawable_called=$next_drawable_called"
  echo "drawable_acquired=$drawable_acquired"
  echo "drawable_texture_observed=$drawable_texture_observed"
  echo "positive_drawable_texture_envelope_before_configuration_required=true"
  echo "bounded_color_attachment_configuration_first_slice_should_execute=$bounded_color_attachment_configuration_first_slice_should_execute"
  echo "bounded_color_attachment_configuration_first_slice_executed=$bounded_color_attachment_configuration_first_slice_executed"
  echo "current_shell_color_attachment_configuration_first_slice_ready=$current_shell_color_attachment_configuration_first_slice_ready"
  echo "color_attachment_configuration_failure_classification=$color_attachment_configuration_failure_classification"
  echo "color_attachment_configuration_failure_domain=$color_attachment_configuration_failure_domain"
  echo "render_pass_descriptor_created=$render_pass_descriptor_created"
  echo "color_attachment_slot_observed=$color_attachment_slot_observed"
  echo "color_attachment_configured=$color_attachment_configured"
  echo "attachment_texture_matches_drawable_texture=$attachment_texture_matches_drawable_texture"
  echo "attachment_load_action_clear=$attachment_load_action_clear"
  echo "attachment_store_action_store=$attachment_store_action_store"
  echo "probe_local_color_attachment_configuration=true"
  echo "production_color_attachment_configuration=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$bounded_color_attachment_configuration_first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_color_attachment_configuration_first_slice_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: route_classification=d3_bounded_result_envelope_color_attachment_configuration_first_slice"
echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: color_attachment_configuration_failure_classification=$color_attachment_configuration_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice packet: renderer_state_write=false"
