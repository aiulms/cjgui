#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 bounded runtime execution 的唯一环境分类入口。
# 它运行 capability detector 并产出 environment packet；Metal-capable 时允许
# 后续 result-envelope script 执行 isolated native probe，非 Metal 时明确跳过。
# Stop-line: 本脚本不执行 native probe，不创建 AppKit / Metal 对象，不写
# renderer state，不扩 native bridge / public API / production C ABI。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-runtime-execution-environment"
CAPABILITY_DETECTOR="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
CAPABILITY_LOG="$TMP_DIR/external-capability-detector.log"
ENVIRONMENT_PACKET="$TMP_DIR/d3-bounded-runtime-execution-environment.packet"

mkdir -p "$TMP_DIR"
: > "$CAPABILITY_LOG"
: > "$ENVIRONMENT_PACKET"

if [[ ! -x "$CAPABILITY_DETECTOR" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: missing capability detector $CAPABILITY_DETECTOR" >&2
  exit 3
fi

if ! env TMPDIR="$TMP_DIR/capability" zsh "$CAPABILITY_DETECTOR" > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: log=$CAPABILITY_LOG" >&2
  exit 4
fi

capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$capability_packet" || ! -f "$capability_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: missing capability packet" >&2
  exit 5
fi

required_capability_facts=(
  "capability_packet_version=1"
  "external_handoff_classification_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_capability_facts[@]}"; do
  if ! grep -F "$fact" "$capability_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: missing capability fact $fact" >&2
    exit 6
  fi
done

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$capability_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="$(grep -Eo '^metal_capable_shell_observed=(true|false)' "$capability_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"

bounded_probe_should_execute="false"
bounded_probe_skip_reason="non_metal_capability"
result_envelope_failure_domain="$failure_domain"
if [[ "$smoke_classification" == "automation_smoke_metal_capable" &&
      "$smoke_exit_code" == "0" &&
      "$metal_capable_shell_observed" == "true" ]]; then
  bounded_probe_should_execute="true"
  bounded_probe_skip_reason="none"
  result_envelope_failure_domain="none"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: protected path modified" >&2
  exit 7
fi

{
  echo "d3_bounded_runtime_execution_environment_packet_version=1"
  echo "capability_detector_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "failure_domain=$result_envelope_failure_domain"
  echo "code_failure_domain=false"
  echo "automation_standing_d3_autonomy_active=true"
  echo "bounded_d3_runtime_native_probe_authorized_by_automation=true"
  echo "bounded_d3_runtime_native_probe_should_execute=$bounded_probe_should_execute"
  echo "bounded_d3_runtime_native_probe_skip_reason=$bounded_probe_skip_reason"
  echo "runtime_native_probe_execution=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$ENVIRONMENT_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: route_classification=d3_bounded_runtime_execution_environment_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: capability_detector_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: environment_packet_path=$ENVIRONMENT_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: bounded_d3_runtime_native_probe_should_execute=$bounded_probe_should_execute"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: bounded_d3_runtime_native_probe_skip_reason=$bounded_probe_skip_reason"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution environment packet: renderer_state_write=false"
