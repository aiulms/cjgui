#!/usr/bin/env zsh
#
# 维护注释：本脚本产出 D3 bounded runtime execution result envelope。
# Metal-capable 时执行 isolated visible-window native probe；非 Metal 时只记录
# environment skip，不把 skipped envelope 当成 production truth。
# Stop-line: 只允许调用 isolated probe script；不写 renderer state，不扩
# runtime/cjgui native bridge / public API / production C ABI。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-runtime-execution-result-envelope"
ENVIRONMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_environment_packet.sh"
SEMANTICS_SCRIPT="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment_result_envelope_semantics.sh"
ISOLATED_PROBE_SCRIPT="$SCRIPT_DIR/verify_native_bridge_drawable_visible_window_environment.sh"
ENVIRONMENT_LOG="$TMP_DIR/d3-bounded-runtime-execution-environment.log"
SEMANTICS_LOG="$TMP_DIR/drawable-visible-window-result-envelope-semantics.log"
ISOLATED_PROBE_LOG="$TMP_DIR/drawable-visible-window-environment.log"
RESULT_ENVELOPE="$TMP_DIR/d3-bounded-runtime-execution-result-envelope.packet"
ENVIRONMENT_PACKET="${CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ENVIRONMENT_LOG"
: > "$SEMANTICS_LOG"
: > "$ISOLATED_PROBE_LOG"
: > "$RESULT_ENVELOPE"

for script in "$ENVIRONMENT_PACKET_SCRIPT" "$SEMANTICS_SCRIPT" "$ISOLATED_PROBE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: missing executable script $script" >&2
    exit 3
  fi
done

if [[ -z "$ENVIRONMENT_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/environment" zsh "$ENVIRONMENT_PACKET_SCRIPT" > "$ENVIRONMENT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: environment packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: log=$ENVIRONMENT_LOG" >&2
    exit 4
  fi
  ENVIRONMENT_PACKET="$(grep -Eo 'environment_packet_path=[^[:space:]]+' "$ENVIRONMENT_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$ENVIRONMENT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: provided environment packet missing $ENVIRONMENT_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_environment_packet_used=true"
    echo "environment_packet_path=$ENVIRONMENT_PACKET"
  } > "$ENVIRONMENT_LOG"
fi

if [[ -z "$ENVIRONMENT_PACKET" || ! -f "$ENVIRONMENT_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: missing environment packet" >&2
  exit 6
fi

required_environment_facts=(
  "d3_bounded_runtime_execution_environment_packet_version=1"
  "capability_detector_passed=true"
  "automation_standing_d3_autonomy_active=true"
  "bounded_d3_runtime_native_probe_authorized_by_automation=true"
  "runtime_native_probe_execution=false"
  "renderer_state_write=false"
)
for fact in "${required_environment_facts[@]}"; do
  if ! grep -F "$fact" "$ENVIRONMENT_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: missing environment fact $fact" >&2
    exit 7
  fi
done

if ! zsh "$SEMANTICS_SCRIPT" > "$SEMANTICS_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: result-envelope semantics regression failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: log=$SEMANTICS_LOG" >&2
  exit 8
fi

should_execute="$(grep -Eo '^bounded_d3_runtime_native_probe_should_execute=(true|false)' "$ENVIRONMENT_PACKET" | tail -1 | cut -d= -f2)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$ENVIRONMENT_PACKET" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$ENVIRONMENT_PACKET" | tail -1 | cut -d= -f2)"
skip_reason="$(grep -Eo '^bounded_d3_runtime_native_probe_skip_reason=[A-Za-z0-9_]+' "$ENVIRONMENT_PACKET" | tail -1 | cut -d= -f2)"

bounded_probe_executed="false"
bounded_probe_exit_code="not_run"
bounded_probe_passed="false"
visible_window_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$ENVIRONMENT_PACKET" | tail -1 | cut -d= -f2)"
failure_count="not_run"
isolated_metal_device_available="not_run"

if [[ "$should_execute" == "true" ]]; then
  set +e
  zsh "$ISOLATED_PROBE_SCRIPT" > "$ISOLATED_PROBE_LOG" 2>&1
  bounded_probe_exit_code="$?"
  set -e
  bounded_probe_executed="true"
  if [[ "$bounded_probe_exit_code" == "0" ]]; then
    bounded_probe_passed="true"
  fi
  visible_window_failure_domain="$(grep -Eo '^visible_window_environment_failure_domain=[A-Za-z0-9_]+' "$ISOLATED_PROBE_LOG" | tail -1 | cut -d= -f2)"
  failure_count="$(grep -Eo '^failure_count=[0-9]+' "$ISOLATED_PROBE_LOG" | tail -1 | cut -d= -f2)"
  isolated_metal_device_available="$(grep -Eo '^isolated_metal_device_available=(true|false)' "$ISOLATED_PROBE_LOG" | tail -1 | cut -d= -f2)"
  if [[ -z "$visible_window_failure_domain" || -z "$failure_count" || -z "$isolated_metal_device_available" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: isolated probe output missing envelope facts" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: log=$ISOLATED_PROBE_LOG" >&2
    exit 9
  fi
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: protected path modified" >&2
  exit 10
fi

{
  echo "d3_bounded_runtime_execution_result_envelope_version=1"
  echo "environment_packet=$ENVIRONMENT_PACKET"
  echo "environment_log=$ENVIRONMENT_LOG"
  echo "result_envelope_semantics_passed=true"
  echo "result_envelope_semantics_log=$SEMANTICS_LOG"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "bounded_d3_runtime_native_probe_should_execute=$should_execute"
  echo "bounded_d3_runtime_native_probe_skip_reason=$skip_reason"
  echo "bounded_d3_runtime_native_probe_executed=$bounded_probe_executed"
  echo "bounded_d3_runtime_native_probe_exit_code=$bounded_probe_exit_code"
  echo "bounded_d3_runtime_native_probe_passed=$bounded_probe_passed"
  echo "isolated_probe_log=$ISOLATED_PROBE_LOG"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "visible_window_environment_failure_domain=$visible_window_failure_domain"
  echo "failure_count=$failure_count"
  echo "failure_domain=$visible_window_failure_domain"
  echo "code_failure_domain=false"
  echo "result_envelope_is_not_production_truth=true"
  echo "runtime_native_probe_execution=$bounded_probe_executed"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$RESULT_ENVELOPE"

echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: route_classification=d3_bounded_runtime_execution_result_envelope"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: result_envelope_path=$RESULT_ENVELOPE"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: result_envelope_semantics_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: bounded_d3_runtime_native_probe_should_execute=$should_execute"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: bounded_d3_runtime_native_probe_executed=$bounded_probe_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: bounded_d3_runtime_native_probe_passed=$bounded_probe_passed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: visible_window_environment_failure_domain=$visible_window_failure_domain"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: runtime_native_probe_execution=$bounded_probe_executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution result envelope: renderer_state_write=false"
