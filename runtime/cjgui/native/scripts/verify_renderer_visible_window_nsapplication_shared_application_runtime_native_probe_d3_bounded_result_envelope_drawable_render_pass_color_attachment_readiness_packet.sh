#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage107 drawable / render-pass color attachment
# readiness packet。它消费 stage106 first-slice suite packet，并串联现有
# descriptor / drawable lifetime / color attachment recovery probes；当前阶段
# 只产出前置顺序与 stop-line envelope，不获取 drawable，不配置 attachment。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage107-drawable-render-pass-color-attachment-readiness-packet"
FIRST_SLICE_OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner.sh"
VISIBLE_WINDOW_PROBE="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment.sh"
COMMAND_QUEUE_PROBE="$SCRIPT_DIR/verify_native_bridge_command_queue_runtime_call.sh"
COMMAND_BUFFER_PROBE="$SCRIPT_DIR/verify_native_bridge_command_buffer_runtime_call.sh"
DESCRIPTOR_PROBE="$SCRIPT_DIR/verify_native_bridge_render_pass_descriptor_create_destroy.sh"
DRAWABLE_ACQUISITION_PLANNING_PROBE="$SCRIPT_DIR/verify_native_bridge_drawable_acquisition_planning.sh"
DRAWABLE_TEXTURE_LIFETIME_PROBE="$SCRIPT_DIR/verify_native_bridge_drawable_texture_lifetime.sh"
COLOR_ATTACHMENT_RECOVERY_PROBE="$SCRIPT_DIR/verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh"
FIRST_SLICE_LOG="$TMP_DIR/stage106-first-slice-input.log"
VISIBLE_WINDOW_LOG="$TMP_DIR/visible-window-environment.log"
COMMAND_QUEUE_LOG="$TMP_DIR/command-queue-runtime-call.log"
COMMAND_BUFFER_LOG="$TMP_DIR/command-buffer-runtime-call.log"
DESCRIPTOR_LOG="$TMP_DIR/render-pass-descriptor-create-destroy.log"
DRAWABLE_ACQUISITION_LOG="$TMP_DIR/drawable-acquisition-planning.log"
DRAWABLE_TEXTURE_LOG="$TMP_DIR/drawable-texture-lifetime.log"
COLOR_ATTACHMENT_LOG="$TMP_DIR/render-pass-color-attachment-recovery.log"
READINESS_PACKET="$TMP_DIR/d3-bounded-result-envelope-drawable-render-pass-color-attachment-readiness.packet"
FIRST_SLICE_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_QUEUE_COMMAND_BUFFER_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage106" "$TMP_DIR/visible-window" "$TMP_DIR/command-queue" "$TMP_DIR/command-buffer" "$TMP_DIR/descriptor" "$TMP_DIR/drawable-acquisition" "$TMP_DIR/drawable-texture" "$TMP_DIR/color-attachment"
: > "$FIRST_SLICE_LOG"
: > "$VISIBLE_WINDOW_LOG"
: > "$COMMAND_QUEUE_LOG"
: > "$COMMAND_BUFFER_LOG"
: > "$DESCRIPTOR_LOG"
: > "$DRAWABLE_ACQUISITION_LOG"
: > "$DRAWABLE_TEXTURE_LOG"
: > "$COLOR_ATTACHMENT_LOG"
: > "$READINESS_PACKET"

for script in "$FIRST_SLICE_OWNER_PROBE" "$VISIBLE_WINDOW_PROBE" "$COMMAND_QUEUE_PROBE" "$COMMAND_BUFFER_PROBE" "$DESCRIPTOR_PROBE" "$DRAWABLE_ACQUISITION_PLANNING_PROBE" "$DRAWABLE_TEXTURE_LIFETIME_PROBE" "$COLOR_ATTACHMENT_RECOVERY_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: syntax check failed $script" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

first_slice_input_mode="direct_owner_visible_window_probe"
stage106_first_slice_suite_passed="false"
stage106_first_slice_contract_input_ready="false"
command_pipeline_readiness_envelope_ready="false"
isolated_metal_device_available="false"
first_slice_should_execute="false"
first_slice_executed="false"
current_shell_first_slice_admitted="false"
first_slice_failure_classification="first_slice_not_classified"
command_queue_probe_passed="false"
command_buffer_probe_passed="false"

if [[ -n "$FIRST_SLICE_SUITE_PACKET" ]]; then
  if [[ ! -f "$FIRST_SLICE_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: provided stage106 packet missing $FIRST_SLICE_SUITE_PACKET" >&2
    exit 6
  fi
  {
    echo "provided_first_slice_suite_packet_used=true"
    echo "suite_packet_path=$FIRST_SLICE_SUITE_PACKET"
    cat "$FIRST_SLICE_SUITE_PACKET"
  } > "$FIRST_SLICE_LOG"
  first_slice_suite_packet="$FIRST_SLICE_SUITE_PACKET"
  required_stage106_facts=(
    "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_suite_passed=true"
    "command_pipeline_readiness_envelope_ready=true"
    "renderer_state_write=false"
    "native_bridge_expansion=false"
    "production_public_c_abi_added=false"
  )
  for fact in "${required_stage106_facts[@]}"; do
    require_file_fact "$first_slice_suite_packet" "$fact"
  done
  first_slice_input_mode="provided_stage106_suite_packet"
  stage106_first_slice_suite_passed="true"
  stage106_first_slice_contract_input_ready="true"
  command_pipeline_readiness_envelope_ready="$(fact_value "$first_slice_suite_packet" "command_pipeline_readiness_envelope_ready")"
  isolated_metal_device_available="$(fact_value "$first_slice_suite_packet" "isolated_metal_device_available")"
  first_slice_should_execute="$(fact_value "$first_slice_suite_packet" "bounded_command_queue_command_buffer_first_slice_should_execute")"
  first_slice_executed="$(fact_value "$first_slice_suite_packet" "bounded_command_queue_command_buffer_first_slice_executed")"
  current_shell_first_slice_admitted="$(fact_value "$first_slice_suite_packet" "current_shell_first_slice_admitted")"
  first_slice_failure_classification="$(fact_value "$first_slice_suite_packet" "first_slice_failure_classification")"
  command_queue_probe_passed="$(fact_value "$first_slice_suite_packet" "command_queue_probe_passed")"
  command_buffer_probe_passed="$(fact_value "$first_slice_suite_packet" "command_buffer_probe_passed")"
else
  if ! zsh "$FIRST_SLICE_OWNER_PROBE" > "$FIRST_SLICE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: stage106 first-slice owner probe failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$FIRST_SLICE_LOG" >&2
    exit 7
  fi
  require_file_fact "$FIRST_SLICE_LOG" "d3_bounded_result_envelope_command_queue_command_buffer_first_slice_owner_present=true"
  require_file_fact "$FIRST_SLICE_LOG" "encoder_creation_blocked=true"
  require_file_fact "$FIRST_SLICE_LOG" "commit_present_blocked=true"
  require_file_fact "$FIRST_SLICE_LOG" "renderer_state_write=false"
  stage106_first_slice_contract_input_ready="true"

  set +e
  env TMPDIR="$TMP_DIR/visible-window" zsh "$VISIBLE_WINDOW_PROBE" > "$VISIBLE_WINDOW_LOG" 2>&1
  visible_window_exit_code="$?"
  set -e
  isolated_metal_device_available="$(fact_value "$VISIBLE_WINDOW_LOG" "isolated_metal_device_available")"
  visible_window_failure_domain="$(fact_value "$VISIBLE_WINDOW_LOG" "visible_window_environment_failure_domain")"
  visible_window_appkit_harness_ready="false"
  if [[ "$(fact_value "$VISIBLE_WINDOW_LOG" "isolated_window_created")" == "true" &&
        "$(fact_value "$VISIBLE_WINDOW_LOG" "isolated_window_visible_observed")" == "true" &&
        "$(fact_value "$VISIBLE_WINDOW_LOG" "isolated_view_attached_observed")" == "true" &&
        "$(fact_value "$VISIBLE_WINDOW_LOG" "isolated_cametallayer_attached_observed")" == "true" &&
        "$(fact_value "$VISIBLE_WINDOW_LOG" "bounded_run_loop_observed")" == "true" &&
        "$(fact_value "$VISIBLE_WINDOW_LOG" "cleanup_observed")" == "true" ]]; then
    visible_window_appkit_harness_ready="true"
  fi
  if [[ "$visible_window_appkit_harness_ready" == "true" && "$isolated_metal_device_available" == "true" ]]; then
    first_slice_should_execute="true"
  elif [[ "$isolated_metal_device_available" == "false" && "$visible_window_failure_domain" == "metal_device_unavailable" ]]; then
    first_slice_failure_classification="host_metal_device_unavailable"
  elif [[ "$visible_window_appkit_harness_ready" != "true" ]]; then
    first_slice_failure_classification="cjgui_visible_window_harness_gap"
  else
    first_slice_failure_classification="blocked_pending_first_slice_suite_packet"
  fi

  if [[ "$first_slice_should_execute" == "true" ]]; then
    if ! env TMPDIR="$TMP_DIR/command-queue" zsh "$COMMAND_QUEUE_PROBE" > "$COMMAND_QUEUE_LOG" 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: command queue native first slice failed" >&2
      echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$COMMAND_QUEUE_LOG" >&2
      exit 8
    fi
    if ! env TMPDIR="$TMP_DIR/command-buffer" zsh "$COMMAND_BUFFER_PROBE" > "$COMMAND_BUFFER_LOG" 2>&1; then
      echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: command buffer native first slice failed" >&2
      echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$COMMAND_BUFFER_LOG" >&2
      exit 9
    fi
    if grep -F "cjgui command queue runtime call probe: success=true" "$COMMAND_QUEUE_LOG" >/dev/null 2>&1 &&
        grep -F "cjgui command queue runtime call probe: passed" "$COMMAND_QUEUE_LOG" >/dev/null 2>&1; then
      command_queue_probe_passed="true"
    fi
    if grep -F "cjgui command buffer runtime call probe: success=true" "$COMMAND_BUFFER_LOG" >/dev/null 2>&1 &&
        grep -F "cjgui command buffer runtime call probe: passed" "$COMMAND_BUFFER_LOG" >/dev/null 2>&1; then
      command_buffer_probe_passed="true"
    fi
    if [[ "$command_queue_probe_passed" == "true" && "$command_buffer_probe_passed" == "true" ]]; then
      first_slice_executed="true"
      current_shell_first_slice_admitted="true"
      first_slice_failure_classification="none"
      command_pipeline_readiness_envelope_ready="true"
    else
      echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: native first slice logs missing success facts" >&2
      exit 10
    fi
  fi
fi

if ! env TMPDIR="$TMP_DIR/descriptor" zsh "$DESCRIPTOR_PROBE" > "$DESCRIPTOR_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: descriptor probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$DESCRIPTOR_LOG" >&2
  exit 11
fi
if ! env TMPDIR="$TMP_DIR/drawable-acquisition" zsh "$DRAWABLE_ACQUISITION_PLANNING_PROBE" > "$DRAWABLE_ACQUISITION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: drawable acquisition planning probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$DRAWABLE_ACQUISITION_LOG" >&2
  exit 12
fi
if ! env TMPDIR="$TMP_DIR/drawable-texture" zsh "$DRAWABLE_TEXTURE_LIFETIME_PROBE" > "$DRAWABLE_TEXTURE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: drawable texture lifetime probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$DRAWABLE_TEXTURE_LOG" >&2
  exit 13
fi
if ! env TMPDIR="$TMP_DIR/color-attachment" zsh "$COLOR_ATTACHMENT_RECOVERY_PROBE" > "$COLOR_ATTACHMENT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: color attachment recovery probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: log=$COLOR_ATTACHMENT_LOG" >&2
  exit 14
fi

for fact in \
  "render_pass_descriptor_create_destroy_probe=passed" \
  "color_attachment_configured=false" \
  "encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false"; do
  require_file_fact "$DESCRIPTOR_LOG" "$fact"
done
for fact in \
  "next_drawable_called=false" \
  "present_called=false" \
  "command_buffer_created=false" \
  "gpu_work_submitted=false" \
  "drawable_acquisition_planning_probe=passed"; do
  require_file_fact "$DRAWABLE_ACQUISITION_LOG" "$fact"
done
for fact in \
  "drawable_texture_lifetime_route=planning_only" \
  "production_drawable_texture_lifetime=false" \
  "production_drawable_acquire_callable=false" \
  "next_drawable_called=false" \
  "present_called=false" \
  "command_buffer_created_by_stage=false" \
  "encoder_created=false" \
  "commit_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "drawable_texture_lifetime_probe=passed"; do
  require_file_fact "$DRAWABLE_TEXTURE_LOG" "$fact"
done
for fact in \
  "color_attachment_recovery_route=recovery_only" \
  "production_drawable_texture_lifetime=false" \
  "descriptor_drawable_cleanup_coownership=false" \
  "color_attachment_configured=false" \
  "encoder_created=false" \
  "draw_called=false" \
  "commit_called=false" \
  "present_called=false" \
  "gpu_work_submitted=false" \
  "render_executed=false" \
  "render_pass_descriptor_color_attachment_recovery_probe=passed"; do
  require_file_fact "$COLOR_ATTACHMENT_LOG" "$fact"
done

drawable_color_attachment_failure_classification="blocked_pending_drawable_texture_lifetime_support"
if [[ "$isolated_metal_device_available" == "false" &&
      "$first_slice_failure_classification" == "host_metal_device_unavailable" ]]; then
  drawable_color_attachment_failure_classification="host_metal_device_unavailable"
elif [[ "$current_shell_first_slice_admitted" != "true" ]]; then
  drawable_color_attachment_failure_classification="blocked_pending_first_slice_admission"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: protected path modified" >&2
  exit 15
fi

{
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_version=1"
  echo "stage106_first_slice_input_mode=$first_slice_input_mode"
  echo "stage106_first_slice_suite_packet=${first_slice_suite_packet:-none}"
  echo "stage106_first_slice_suite_passed=$stage106_first_slice_suite_passed"
  echo "stage106_first_slice_contract_input_ready=$stage106_first_slice_contract_input_ready"
  echo "stage106_first_slice_log=$FIRST_SLICE_LOG"
  echo "visible_window_log=$VISIBLE_WINDOW_LOG"
  echo "command_queue_log=$COMMAND_QUEUE_LOG"
  echo "command_buffer_log=$COMMAND_BUFFER_LOG"
  echo "descriptor_log=$DESCRIPTOR_LOG"
  echo "drawable_acquisition_log=$DRAWABLE_ACQUISITION_LOG"
  echo "drawable_texture_lifetime_log=$DRAWABLE_TEXTURE_LOG"
  echo "color_attachment_log=$COLOR_ATTACHMENT_LOG"
  echo "render_pass_descriptor_create_destroy_probe_passed=true"
  echo "drawable_acquisition_planning_probe_passed=true"
  echo "drawable_texture_lifetime_probe_passed=true"
  echo "render_pass_descriptor_color_attachment_recovery_probe_passed=true"
  echo "command_queue_probe_passed=$command_queue_probe_passed"
  echo "command_buffer_probe_passed=$command_buffer_probe_passed"
  echo "command_pipeline_readiness_envelope_ready=$command_pipeline_readiness_envelope_ready"
  echo "drawable_render_pass_color_attachment_readiness_envelope_ready=true"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "bounded_command_queue_command_buffer_first_slice_should_execute=$first_slice_should_execute"
  echo "bounded_command_queue_command_buffer_first_slice_executed=$first_slice_executed"
  echo "current_shell_first_slice_admitted=$current_shell_first_slice_admitted"
  echo "first_slice_failure_classification=$first_slice_failure_classification"
  echo "first_slice_admission_before_drawable_acquisition_required=true"
  echo "drawable_acquisition_blocked_until_admitted_first_slice=true"
  echo "drawable_texture_lifetime_before_color_attachment_required=true"
  echo "render_pass_descriptor_before_color_attachment_required=true"
  echo "descriptor_drawable_layer_device_cleanup_coownership_required=true"
  echo "production_drawable_texture_lifetime=false"
  echo "production_drawable_acquire_callable=false"
  echo "descriptor_drawable_cleanup_coownership=false"
  echo "current_shell_drawable_color_attachment_native_execution_ready=false"
  echo "bounded_drawable_render_pass_color_attachment_executed=false"
  echo "drawable_color_attachment_failure_classification=$drawable_color_attachment_failure_classification"
  echo "next_drawable_called=false"
  echo "color_attachment_configured=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$first_slice_executed"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet_passed=true"
} > "$READINESS_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: route_classification=d3_bounded_result_envelope_drawable_render_pass_color_attachment_readiness_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: readiness_packet_path=$READINESS_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: drawable_render_pass_color_attachment_readiness_envelope_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: current_shell_drawable_color_attachment_native_execution_ready=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: drawable_color_attachment_failure_classification=$drawable_color_attachment_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded drawable render pass color attachment readiness packet: renderer_state_write=false"
