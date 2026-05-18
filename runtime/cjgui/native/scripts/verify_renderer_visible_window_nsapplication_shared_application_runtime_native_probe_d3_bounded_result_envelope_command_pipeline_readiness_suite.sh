#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage105 visible-window command-pipeline readiness
# focused suite。它复用 stage104 join packet，生成 command-pipeline readiness
# envelope，并保持 renderer state write blocked。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage105-command-pipeline-readiness-suite"
JOIN_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_suite.sh"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_command_pipeline_readiness_source_build_guard.sh"
JOIN_LOG="$TMP_DIR/stage104-join-suite.log"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-command-pipeline-readiness-suite.packet"

mkdir -p "$TMP_DIR"
: > "$JOIN_LOG"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$JOIN_SUITE_SCRIPT" "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! env TMPDIR="$TMP_DIR/stage104-join" zsh "$JOIN_SUITE_SCRIPT" > "$JOIN_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: stage104 join suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: log=$JOIN_LOG" >&2
  exit 5
fi
join_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$JOIN_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$join_suite_packet" || ! -f "$join_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing join suite packet" >&2
  exit 6
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: log=$OWNER_LOG" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_SUITE_PACKET="$join_suite_packet" \
  zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: command pipeline packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: log=$PACKET_LOG" >&2
  exit 8
fi
command_pipeline_packet="$(grep -Eo 'command_pipeline_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$command_pipeline_packet" || ! -f "$command_pipeline_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing command pipeline packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_PACKET="$command_pipeline_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: log=$CLASSIFIER_LOG" >&2
  exit 10
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing classifier packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_PACKET="$command_pipeline_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_COMMAND_PIPELINE_READINESS_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing source build packet" >&2
  exit 13
fi

required_suite_facts=(
  "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
  "d3_bounded_result_envelope_command_pipeline_readiness_classifier_passed=true"
  "source_build_command_pipeline_readiness_guard_passed=true"
  "visible_window_appkit_harness_ready=true"
  "command_pipeline_host_independent_probes_ready=true"
  "command_pipeline_readiness_envelope_ready=true"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$command_pipeline_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: missing fact $fact" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: protected path modified" >&2
  exit 15
fi

current_shell_failure_classification="$(grep -E '^current_shell_failure_classification=' "$classifier_packet" | tail -1 | cut -d= -f2-)"
isolated_metal_device_available="$(grep -E '^isolated_metal_device_available=' "$command_pipeline_packet" | tail -1 | cut -d= -f2-)"
current_shell_command_pipeline_native_execution_ready="$(grep -E '^current_shell_command_pipeline_native_execution_ready=' "$command_pipeline_packet" | tail -1 | cut -d= -f2-)"
runtime_native_probe_execution="$(grep -E '^runtime_native_probe_execution=' "$command_pipeline_packet" | tail -1 | cut -d= -f2-)"
visible_window_environment_failure_domain="$(grep -E '^visible_window_environment_failure_domain=' "$command_pipeline_packet" | tail -1 | cut -d= -f2-)"

{
  echo "d3_bounded_result_envelope_command_pipeline_readiness_suite_version=1"
  echo "join_log=$JOIN_LOG"
  echo "join_suite_packet=$join_suite_packet"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "command_pipeline_packet=$command_pipeline_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_packet_passed=true"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_classifier_passed=true"
  echo "source_build_command_pipeline_readiness_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_command_pipeline_readiness_suite_passed=true"
  echo "visible_window_appkit_harness_ready=true"
  echo "visible_window_environment_failure_domain=$visible_window_environment_failure_domain"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  grep -E '^host_metal_unavailable_classified=' "$command_pipeline_packet" | tail -1
  echo "current_shell_failure_classification=$current_shell_failure_classification"
  echo "command_pipeline_host_independent_probes_ready=true"
  echo "command_pipeline_readiness_envelope_ready=true"
  echo "current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
  echo "bounded_d3_command_pipeline_should_execute=$current_shell_command_pipeline_native_execution_ready"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "next_drawable_called=false"
  echo "command_queue_created_by_stage=false"
  echo "command_buffer_created_by_stage=false"
  echo "encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "gpu_work_submitted=false"
  echo "render_executed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "production_write_admission_before_renderer_state_write_required=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: route_classification=d3_bounded_result_envelope_command_pipeline_readiness_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: d3_bounded_result_envelope_command_pipeline_readiness_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: visible_window_appkit_harness_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: isolated_metal_device_available=$isolated_metal_device_available"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: current_shell_failure_classification=$current_shell_failure_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: command_pipeline_readiness_envelope_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: current_shell_command_pipeline_native_execution_ready=$current_shell_command_pipeline_native_execution_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope command pipeline readiness suite: renderer_state_write=false"
