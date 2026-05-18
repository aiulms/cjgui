#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 D3 environment recovery native packet 并输出 route
# classifier。它把 current shell Metal-unavailable、D3 approval 未消费、bounded
# native fail-closed evidence 与 next route 分开。
# Truth: recovery classifier；不消费 D3 approval，不执行 runtime native probe，不调用
# application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-environment-recovery-classifier"
NATIVE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_native_packet.sh"
NATIVE_LOG="$TMP_DIR/d3-environment-recovery-native-packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-environment-recovery-classifier.packet"
EXTERNAL_NATIVE_PACKET="${CJGUI_D3_ENVIRONMENT_RECOVERY_NATIVE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$NATIVE_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$NATIVE_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: missing executable native packet script $NATIVE_PACKET_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: current shell is recovery-only and must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_NATIVE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_NATIVE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: external native packet missing $EXTERNAL_NATIVE_PACKET" >&2
    exit 5
  fi
  {
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: external_native_packet_used=true"
    echo "route_classification=d3_environment_recovery_native_packet"
    echo "native_packet_path=$EXTERNAL_NATIVE_PACKET"
    cat "$EXTERNAL_NATIVE_PACKET"
  } > "$NATIVE_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-native" zsh "$NATIVE_PACKET_SCRIPT" > "$NATIVE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: native packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: log=$NATIVE_LOG" >&2
    exit 6
  fi
fi

required_native_facts=(
  "route_classification=d3_environment_recovery_native_packet"
  "capability_detector_passed=true"
  "stage93_replay_checkpoint_suite_passed=true"
  "isolated_accessor_disabled_fail_closed=true"
  "throwaway_creation_disabled_fail_closed=true"
  "bounded_native_fail_closed_packet_ready=true"
  "smoke_exit_code=20"
  "smoke_environment_classification=automation_smoke_metal_unavailable"
  "failure_domain=automation_environment"
  "external_metal_capable_shell_required=true"
  "metal_capable_shell_observed=false"
  "d3_limited_approval_available_but_unconsumed=true"
  "recovery_route_switch_required=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_native_facts[@]}"; do
  if ! grep -F "$fact" "$NATIVE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: missing native fact $fact" >&2
    exit 7
  fi
done

native_packet="${EXTERNAL_NATIVE_PACKET:-$(grep -Eo 'native_packet_path=[^[:space:]]+' "$NATIVE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$native_packet" || ! -f "$native_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: missing native packet $native_packet" >&2
  exit 8
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: protected path modified" >&2
  exit 9
fi

{
  echo "d3_environment_recovery_classifier_version=1"
  echo "native_packet=$native_packet"
  echo "native_log=$NATIVE_LOG"
  echo "d3_execution_precondition_met=false"
  echo "d3_execution_denied_by_current_environment=true"
  echo "d3_execution_failure_domain=automation_environment"
  echo "d3_execution_recovery_route_classified=true"
  echo "external_metal_capable_shell_required=true"
  echo "metal_capable_shell_observed=false"
  echo "bounded_native_fail_closed_packet_reused=true"
  echo "stage93_replay_checkpoint_reused=true"
  echo "d3_limited_approval_available_but_unconsumed=true"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: route_classification=d3_environment_recovery_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: d3_execution_precondition_met=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: d3_execution_denied_by_current_environment=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: d3_execution_failure_domain=automation_environment"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: d3_execution_recovery_route_classified=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: external_metal_capable_shell_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: metal_capable_shell_observed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: bounded_native_fail_closed_packet_reused=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: stage93_replay_checkpoint_reused=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: d3_limited_approval_available_but_unconsumed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery classifier: next_route=external_metal_capable_shell_d3_execution_or_recovery_packet_reuse"
