#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage105 command-pipeline readiness packet。它把
# AppKit harness readiness、host Metal availability、host-independent
# command-pipeline stop-line probes 分开输出。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage105-command-pipeline-readiness-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_packet.sh"
PACKET_LOG="$TMP_DIR/command-pipeline-packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-pipeline-readiness-classifier.packet"
COMMAND_PIPELINE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi

if [[ -n "$COMMAND_PIPELINE_PACKET" ]]; then
  if [[ ! -f "$COMMAND_PIPELINE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: command pipeline packet missing $COMMAND_PIPELINE_PACKET" >&2
    exit 4
  fi
  {
    echo "provided_command_pipeline_packet_used=true"
    echo "command_pipeline_packet_path=$COMMAND_PIPELINE_PACKET"
    cat "$COMMAND_PIPELINE_PACKET"
  } > "$PACKET_LOG"
else
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: log=$PACKET_LOG" >&2
    exit 5
  fi
fi

command_pipeline_packet="${COMMAND_PIPELINE_PACKET:-$(grep -Eo 'command_pipeline_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$command_pipeline_packet" || ! -f "$command_pipeline_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: missing command pipeline packet" >&2
  exit 6
fi

require_fact() {
  local fact="$1"
  if ! grep -F "$fact" "$command_pipeline_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: missing packet fact $fact" >&2
    exit 7
  fi
}

fact_value() {
  local key="$1"
  grep -E "^${key}=" "$command_pipeline_packet" | tail -1 | cut -d= -f2- || true
}

required_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
  "stage104_join_suite_passed=true"
  "fixture_guarded_write_decision_join_preflight_ready=true"
  "visible_window_appkit_harness_ready=true"
  "render_pass_descriptor_probe_passed=true"
  "pipeline_descriptor_configuration_probe_passed=true"
  "drawable_texture_lifetime_stopline_probe_passed=true"
  "draw_call_still_blocked_probe_passed=true"
  "command_pipeline_host_independent_probes_ready=true"
  "command_pipeline_readiness_envelope_ready=true"
  "production_write_admission_before_renderer_state_write_required=true"
  "renderer_state_write=false"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_facts[@]}"; do
  require_fact "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: protected path modified" >&2
  exit 8
fi

metal_device_available="$(fact_value "isolated_metal_device_available")"
host_metal_unavailable_classified="$(fact_value "host_metal_unavailable_classified")"
cjgui_harness_gap_detected="$(fact_value "cjgui_harness_gap_detected")"
current_shell_command_pipeline_native_execution_ready="$(fact_value "current_shell_command_pipeline_native_execution_ready")"
visible_window_environment_failure_domain="$(fact_value "visible_window_environment_failure_domain")"
current_shell_smoke_environment_classification="$(fact_value "current_shell_smoke_environment_classification")"

current_shell_failure_classification="none"
if [[ "$host_metal_unavailable_classified" == "true" ]]; then
  current_shell_failure_classification="host_metal_device_unavailable"
elif [[ "$cjgui_harness_gap_detected" == "true" ]]; then
  current_shell_failure_classification="cjgui_visible_window_harness_gap"
fi

bounded_d3_command_pipeline_should_execute="$current_shell_command_pipeline_native_execution_ready"
if [[ "$metal_device_available" == "false" && "$host_metal_unavailable_classified" != "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: Metal unavailable without host classification" >&2
  exit 9
fi
if [[ "$cjgui_harness_gap_detected" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: CJGUI harness gap detected" >&2
  exit 10
fi

{
  echo "d3_bounded_result_envelope_command_pipeline_readiness_classifier_packet_version=1"
  echo "command_pipeline_packet=$command_pipeline_packet"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_classifier_passed=true"
  echo "visible_window_appkit_harness_ready=true"
  echo "isolated_metal_device_available=$metal_device_available"
  echo "host_metal_unavailable_classified=$host_metal_unavailable_classified"
  echo "visible_window_environment_failure_domain=$visible_window_environment_failure_domain"
  echo "current_shell_smoke_environment_classification=$current_shell_smoke_environment_classification"
  echo "current_shell_failure_classification=$current_shell_failure_classification"
  echo "command_pipeline_host_independent_probes_ready=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  echo "current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
  echo "bounded_d3_command_pipeline_should_execute=$bounded_d3_command_pipeline_should_execute"
  echo "appkit_harness_failure_domain=false"
  echo "cjgui_harness_gap_detected=false"
  echo "layer_device_binding_before_drawable_required=true"
  echo "metal_device_before_command_queue_required=true"
  echo "drawable_before_render_pass_color_attachment_required=true"
  echo "command_queue_before_command_buffer_required=true"
  echo "command_buffer_and_render_pass_before_encoder_required=true"
  echo "pipeline_state_and_vertex_buffer_before_draw_required=true"
  echo "commit_present_after_encoding_required=true"
  echo "current_shell_drawable_acquisition_allowed=$current_shell_command_pipeline_native_execution_ready"
  echo "current_shell_command_queue_creation_allowed=$current_shell_command_pipeline_native_execution_ready"
  echo "current_shell_render_pass_encoder_allowed=false"
  echo "next_drawable_called=false"
  echo "command_queue_created_by_stage=false"
  echo "command_buffer_created_by_stage=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$(fact_value "runtime_native_probe_execution")"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: route_classification=d3_bounded_result_envelope_command_pipeline_readiness_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: current_shell_failure_classification=$current_shell_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: command_pipeline_readiness_envelope_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness classifier: renderer_state_write=false"
