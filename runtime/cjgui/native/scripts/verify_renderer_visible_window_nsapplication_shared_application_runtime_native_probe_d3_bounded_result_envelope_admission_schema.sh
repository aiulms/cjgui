#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage102 bounded runtime execution result envelope 的
# admission schema。若未传入现成 envelope，它会通过 stage102 bounded result
# envelope 脚本生成一次；Metal-capable 时这会执行 isolated visible-window probe。
# Stop-line: 只复用 stage102 bounded route；不写 renderer state，不扩 native
# bridge / public API / production C ABI。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-admission-schema"
RESULT_ENVELOPE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_result_envelope.sh"
RESULT_ENVELOPE_LOG="$TMP_DIR/bounded-runtime-execution-result-envelope.log"
SCHEMA_PACKET="$TMP_DIR/d3-bounded-result-envelope-admission-schema.packet"
RESULT_ENVELOPE="${CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE:-}"

mkdir -p "$TMP_DIR"
: > "$RESULT_ENVELOPE_LOG"
: > "$SCHEMA_PACKET"

if [[ ! -x "$RESULT_ENVELOPE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: missing result envelope script $RESULT_ENVELOPE_SCRIPT" >&2
  exit 3
fi

if [[ -z "$RESULT_ENVELOPE" ]]; then
  if ! env TMPDIR="$TMP_DIR/result-envelope" zsh "$RESULT_ENVELOPE_SCRIPT" > "$RESULT_ENVELOPE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: result envelope failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: log=$RESULT_ENVELOPE_LOG" >&2
    exit 4
  fi
  RESULT_ENVELOPE="$(grep -Eo 'result_envelope_path=[^[:space:]]+' "$RESULT_ENVELOPE_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$RESULT_ENVELOPE" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: provided result envelope missing $RESULT_ENVELOPE" >&2
    exit 5
  fi
  {
    echo "provided_result_envelope_used=true"
    echo "result_envelope_path=$RESULT_ENVELOPE"
  } > "$RESULT_ENVELOPE_LOG"
fi

if [[ -z "$RESULT_ENVELOPE" || ! -f "$RESULT_ENVELOPE" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: missing result envelope" >&2
  exit 6
fi

required_result_facts=(
  "d3_bounded_runtime_execution_result_envelope_version=1"
  "result_envelope_semantics_passed=true"
  "result_envelope_is_not_production_truth=true"
  "code_failure_domain=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)
for fact in "${required_result_facts[@]}"; do
  if ! grep -F "$fact" "$RESULT_ENVELOPE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: missing result fact $fact" >&2
    exit 7
  fi
done

should_execute="$(grep -Eo '^bounded_d3_runtime_native_probe_should_execute=(true|false)' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
executed="$(grep -Eo '^bounded_d3_runtime_native_probe_executed=(true|false)' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
passed="$(grep -Eo '^bounded_d3_runtime_native_probe_passed=(true|false)' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
exit_code="$(grep -Eo '^bounded_d3_runtime_native_probe_exit_code=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
failure_count="$(grep -Eo '^failure_count=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
isolated_metal_device_available="$(grep -Eo '^isolated_metal_device_available=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$RESULT_ENVELOPE" | tail -1 | cut -d= -f2)"

if [[ -z "$should_execute" || -z "$executed" || -z "$passed" ||
      -z "$exit_code" || -z "$failure_domain" || -z "$failure_count" ||
      -z "$isolated_metal_device_available" || -z "$smoke_classification" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: missing parsed result facts" >&2
  exit 8
fi

if [[ "$should_execute" == "true" && "$executed" != "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: executable envelope did not execute" >&2
  exit 9
fi
if [[ "$should_execute" == "false" && "$executed" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: skipped envelope unexpectedly executed" >&2
  exit 10
fi

admission_candidate="false"
admission_denial_reason="not_executed_or_not_passed"
if [[ "$executed" == "true" && "$passed" == "true" ]]; then
  if [[ "$exit_code" != "0" || "$failure_domain" != "none" ||
        "$failure_count" != "0" ||
        "$isolated_metal_device_available" != "true" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: passed envelope has inconsistent success facts" >&2
    exit 11
  fi
  admission_candidate="true"
  admission_denial_reason="none"
elif [[ "$executed" == "false" ]]; then
  if [[ "$exit_code" != "not_run" || "$failure_count" != "not_run" ||
        "$isolated_metal_device_available" != "not_run" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: skipped envelope has inconsistent skip facts" >&2
    exit 12
  fi
  admission_denial_reason="bounded_probe_not_executed"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: protected path modified" >&2
  exit 13
fi

{
  echo "d3_bounded_result_envelope_admission_schema_version=1"
  echo "result_envelope=$RESULT_ENVELOPE"
  echo "result_envelope_log=$RESULT_ENVELOPE_LOG"
  echo "bounded_result_envelope_schema_valid=true"
  echo "smoke_environment_classification=$smoke_classification"
  echo "bounded_d3_runtime_native_probe_should_execute=$should_execute"
  echo "bounded_d3_runtime_native_probe_executed=$executed"
  echo "bounded_d3_runtime_native_probe_passed=$passed"
  echo "bounded_d3_runtime_native_probe_exit_code=$exit_code"
  echo "isolated_metal_device_available=$isolated_metal_device_available"
  echo "visible_window_environment_failure_domain=$failure_domain"
  echo "failure_domain=$failure_domain"
  echo "failure_count=$failure_count"
  echo "bounded_result_envelope_admission_candidate=$admission_candidate"
  echo "bounded_result_envelope_admission_denial_reason=$admission_denial_reason"
  echo "result_envelope_is_not_production_truth=true"
  echo "result_envelope_isolated_evidence_only=true"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$executed"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$SCHEMA_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: route_classification=d3_bounded_result_envelope_admission_schema"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: schema_packet_path=$SCHEMA_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: bounded_result_envelope_schema_valid=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: bounded_d3_runtime_native_probe_executed=$executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: bounded_d3_runtime_native_probe_passed=$passed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: bounded_result_envelope_admission_candidate=$admission_candidate"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: runtime_native_probe_execution=$executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission schema: renderer_state_write=false"
