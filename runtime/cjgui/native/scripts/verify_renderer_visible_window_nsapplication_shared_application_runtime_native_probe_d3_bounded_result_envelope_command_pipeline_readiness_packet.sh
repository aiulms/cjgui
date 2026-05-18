#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage105 visible-window command-pipeline readiness
# packet。它重跑 AppKit visible-window probe，并把 Metal device nil 与
# CJGUI harness 缺口分开分类；同时重跑 host-independent command-pipeline
# native stop-line probes。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage105-command-pipeline-readiness-packet"
JOIN_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_suite.sh"
VISIBLE_WINDOW_PROBE="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment.sh"
RENDER_PASS_DESCRIPTOR_PROBE="$SCRIPT_DIR/verify_native_bridge_render_pass_descriptor_create_destroy.sh"
PIPELINE_DESCRIPTOR_PROBE="$SCRIPT_DIR/verify_native_bridge_pipeline_descriptor_configuration.sh"
DRAWABLE_TEXTURE_LIFETIME_PROBE="$SCRIPT_DIR/verify_native_bridge_drawable_texture_lifetime.sh"
DRAW_CALL_BLOCKED_PROBE="$SCRIPT_DIR/verify_native_bridge_draw_call_still_blocked.sh"
JOIN_LOG="$TMP_DIR/stage104-join-suite.log"
VISIBLE_LOG="$TMP_DIR/visible-window-environment.log"
RENDER_PASS_LOG="$TMP_DIR/render-pass-descriptor.log"
PIPELINE_DESCRIPTOR_LOG="$TMP_DIR/pipeline-descriptor.log"
DRAWABLE_TEXTURE_LOG="$TMP_DIR/drawable-texture-lifetime.log"
DRAW_CALL_LOG="$TMP_DIR/draw-call-still-blocked.log"
COMMAND_PIPELINE_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-pipeline-readiness.packet"
JOIN_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$JOIN_LOG"
: > "$VISIBLE_LOG"
: > "$RENDER_PASS_LOG"
: > "$PIPELINE_DESCRIPTOR_LOG"
: > "$DRAWABLE_TEXTURE_LOG"
: > "$DRAW_CALL_LOG"
: > "$COMMAND_PIPELINE_PACKET"

for script in "$JOIN_SUITE_SCRIPT" "$VISIBLE_WINDOW_PROBE" \
  "$RENDER_PASS_DESCRIPTOR_PROBE" "$PIPELINE_DESCRIPTOR_PROBE" \
  "$DRAWABLE_TEXTURE_LIFETIME_PROBE" "$DRAW_CALL_BLOCKED_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: missing executable script $script" >&2
    exit 3
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

prefixed_or_plain_fact_value() {
  local file="$1"
  local key="$2"
  grep -E "(^|[[:space:]])${key}=" "$file" | tail -1 | sed -E "s/^.*${key}=//" || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: missing fact $fact in $file" >&2
    exit 4
  fi
}

if [[ -n "$JOIN_SUITE_PACKET" ]]; then
  if [[ ! -f "$JOIN_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: join suite packet missing $JOIN_SUITE_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_join_suite_packet_used=true"
    echo "suite_packet_path=$JOIN_SUITE_PACKET"
    cat "$JOIN_SUITE_PACKET"
  } > "$JOIN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/stage104-join" zsh "$JOIN_SUITE_SCRIPT" > "$JOIN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: stage104 join suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: log=$JOIN_LOG" >&2
    exit 6
  fi
fi

join_suite_packet="${JOIN_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$JOIN_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$join_suite_packet" || ! -f "$join_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: missing join suite packet" >&2
  exit 7
fi

required_join_facts=(
  "d3_bounded_result_envelope_renderer_state_write_decision_join_suite_passed=true"
  "fixture_guarded_write_decision_join_preflight_ready=true"
  "join_preflight_is_not_renderer_state_write_permission=true"
  "production_write_admission_after_join_preflight_required=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_join_facts[@]}"; do
  require_file_fact "$join_suite_packet" "$fact"
done

set +e
env TMPDIR="$TMP_DIR/visible-window" zsh "$VISIBLE_WINDOW_PROBE" > "$VISIBLE_LOG" 2>&1
visible_probe_exit_code="$?"
set -e

if ! env TMPDIR="$TMP_DIR/render-pass" zsh "$RENDER_PASS_DESCRIPTOR_PROBE" > "$RENDER_PASS_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: render pass descriptor probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: log=$RENDER_PASS_LOG" >&2
  exit 8
fi
if ! env TMPDIR="$TMP_DIR/pipeline-descriptor" zsh "$PIPELINE_DESCRIPTOR_PROBE" > "$PIPELINE_DESCRIPTOR_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: pipeline descriptor probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: log=$PIPELINE_DESCRIPTOR_LOG" >&2
  exit 9
fi
if ! env TMPDIR="$TMP_DIR/drawable-texture" zsh "$DRAWABLE_TEXTURE_LIFETIME_PROBE" > "$DRAWABLE_TEXTURE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: drawable texture lifetime probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: log=$DRAWABLE_TEXTURE_LOG" >&2
  exit 10
fi
if ! env TMPDIR="$TMP_DIR/draw-call" zsh "$DRAW_CALL_BLOCKED_PROBE" > "$DRAW_CALL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: draw call blocked probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: log=$DRAW_CALL_LOG" >&2
  exit 11
fi

visible_window_created="$(fact_value "$VISIBLE_LOG" "isolated_window_created")"
visible_window_visible="$(fact_value "$VISIBLE_LOG" "isolated_window_visible_observed")"
visible_view_attached="$(fact_value "$VISIBLE_LOG" "isolated_view_attached_observed")"
visible_layer_attached="$(fact_value "$VISIBLE_LOG" "isolated_cametallayer_attached_observed")"
visible_bounded_run_loop="$(fact_value "$VISIBLE_LOG" "bounded_run_loop_observed")"
visible_cleanup_observed="$(fact_value "$VISIBLE_LOG" "cleanup_observed")"
metal_device_available="$(fact_value "$VISIBLE_LOG" "isolated_metal_device_available")"
visible_failure_domain="$(fact_value "$VISIBLE_LOG" "visible_window_environment_failure_domain")"
current_shell_smoke_classification="$(fact_value "$join_suite_packet" "current_shell_smoke_environment_classification")"
fixture_join_ready="$(fact_value "$join_suite_packet" "fixture_guarded_write_decision_join_preflight_ready")"
current_join_ready="$(fact_value "$join_suite_packet" "current_shell_guarded_write_decision_join_preflight_ready")"
runtime_native_probe_execution="$(fact_value "$join_suite_packet" "runtime_native_probe_execution")"

appkit_harness_ready="false"
if [[ "$visible_window_created" == "true" &&
      "$visible_window_visible" == "true" &&
      "$visible_view_attached" == "true" &&
      "$visible_layer_attached" == "true" &&
      "$visible_bounded_run_loop" == "true" &&
      "$visible_cleanup_observed" == "true" ]]; then
  appkit_harness_ready="true"
fi

host_metal_unavailable_classified="false"
if [[ "$metal_device_available" == "false" &&
      "$visible_failure_domain" == "metal_device_unavailable" ]]; then
  host_metal_unavailable_classified="true"
fi

cjgui_harness_gap_detected="false"
if [[ "$appkit_harness_ready" != "true" ]]; then
  cjgui_harness_gap_detected="true"
fi

render_pass_descriptor_ready="false"
pipeline_descriptor_ready="false"
drawable_texture_stopline_ready="false"
draw_call_stopline_ready="false"
if grep -F "render_pass_descriptor_create_destroy_probe=passed" "$RENDER_PASS_LOG" >/dev/null 2>&1; then
  render_pass_descriptor_ready="true"
fi
if grep -F "pipeline_descriptor_configuration_probe=passed" "$PIPELINE_DESCRIPTOR_LOG" >/dev/null 2>&1; then
  pipeline_descriptor_ready="true"
fi
if grep -F "drawable_texture_lifetime_probe=passed" "$DRAWABLE_TEXTURE_LOG" >/dev/null 2>&1; then
  drawable_texture_stopline_ready="true"
fi
if grep -F "draw_call_still_blocked_probe=passed" "$DRAW_CALL_LOG" >/dev/null 2>&1; then
  draw_call_stopline_ready="true"
fi

command_pipeline_host_independent_probes_ready="false"
if [[ "$render_pass_descriptor_ready" == "true" &&
      "$pipeline_descriptor_ready" == "true" &&
      "$drawable_texture_stopline_ready" == "true" &&
      "$draw_call_stopline_ready" == "true" ]]; then
  command_pipeline_host_independent_probes_ready="true"
fi

command_pipeline_readiness_envelope_ready="false"
if [[ "$fixture_join_ready" == "true" &&
      "$appkit_harness_ready" == "true" &&
      "$command_pipeline_host_independent_probes_ready" == "true" ]]; then
  command_pipeline_readiness_envelope_ready="true"
fi

current_shell_command_pipeline_native_execution_ready="false"
if [[ "$command_pipeline_readiness_envelope_ready" == "true" &&
      "$metal_device_available" == "true" ]]; then
  current_shell_command_pipeline_native_execution_ready="true"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: protected path modified" >&2
  exit 12
fi

{
  echo "d3_bounded_result_envelope_command_pipeline_readiness_packet_version=1"
  echo "stage104_join_suite_packet=$join_suite_packet"
  echo "stage104_join_suite_passed=true"
  echo "current_shell_smoke_environment_classification=$current_shell_smoke_classification"
  echo "current_shell_guarded_write_decision_join_preflight_ready=$current_join_ready"
  echo "fixture_guarded_write_decision_join_preflight_ready=$fixture_join_ready"
  echo "visible_window_environment_log=$VISIBLE_LOG"
  echo "visible_window_probe_exit_code=$visible_probe_exit_code"
  echo "visible_window_environment_failure_domain=$visible_failure_domain"
  echo "visible_window_appkit_harness_ready=$appkit_harness_ready"
  echo "isolated_window_created=$visible_window_created"
  echo "isolated_window_visible_observed=$visible_window_visible"
  echo "isolated_view_attached_observed=$visible_view_attached"
  echo "isolated_cametallayer_attached_observed=$visible_layer_attached"
  echo "bounded_run_loop_observed=$visible_bounded_run_loop"
  echo "cleanup_observed=$visible_cleanup_observed"
  echo "isolated_metal_device_available=$metal_device_available"
  echo "host_metal_unavailable_classified=$host_metal_unavailable_classified"
  echo "cjgui_harness_gap_detected=$cjgui_harness_gap_detected"
  echo "render_pass_descriptor_log=$RENDER_PASS_LOG"
  echo "render_pass_descriptor_probe_passed=$render_pass_descriptor_ready"
  echo "pipeline_descriptor_log=$PIPELINE_DESCRIPTOR_LOG"
  echo "pipeline_descriptor_configuration_probe_passed=$pipeline_descriptor_ready"
  echo "drawable_texture_lifetime_log=$DRAWABLE_TEXTURE_LOG"
  echo "drawable_texture_lifetime_stopline_probe_passed=$drawable_texture_stopline_ready"
  echo "draw_call_log=$DRAW_CALL_LOG"
  echo "draw_call_still_blocked_probe_passed=$draw_call_stopline_ready"
  echo "command_pipeline_host_independent_probes_ready=$command_pipeline_host_independent_probes_ready"
  echo "command_pipeline_readiness_envelope_ready=$command_pipeline_readiness_envelope_ready"
  echo "current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
  echo "layer_device_binding_before_drawable_required=true"
  echo "metal_device_before_command_queue_required=true"
  echo "drawable_before_render_pass_color_attachment_required=true"
  echo "command_queue_before_command_buffer_required=true"
  echo "command_buffer_and_render_pass_before_encoder_required=true"
  echo "pipeline_state_and_vertex_buffer_before_draw_required=true"
  echo "commit_present_after_encoding_required=true"
  echo "next_drawable_called=false"
  echo "command_queue_created_by_stage=false"
  echo "command_buffer_created_by_stage=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "protected_path_modified=false"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
} > "$COMMAND_PIPELINE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: route_classification=d3_bounded_result_envelope_command_pipeline_readiness_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: command_pipeline_packet_path=$COMMAND_PIPELINE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: visible_window_appkit_harness_ready=$appkit_harness_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: isolated_metal_device_available=$metal_device_available"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: host_metal_unavailable_classified=$host_metal_unavailable_classified"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: command_pipeline_readiness_envelope_ready=$command_pipeline_readiness_envelope_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness packet: renderer_state_write=false"
