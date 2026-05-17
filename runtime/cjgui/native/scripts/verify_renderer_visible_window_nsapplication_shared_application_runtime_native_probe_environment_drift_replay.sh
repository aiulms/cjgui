#!/usr/bin/env zsh
#
# 维护注释：本脚本重放 explicit approval gate packet 与 external capability
# detector，把 automation shell 从 Metal-unavailable 到 Metal-capable 的漂移分类为
# environment/capability drift，而不是 D3 execution approval。
# Truth: environment / failure-domain classification 后续路线；不执行 runtime
# native probe，不消费 D3 approval，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-environment-drift-replay"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
APPROVAL_GATE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_packet.sh"
CAPABILITY_DETECTOR="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
APPROVAL_LOG="$TMP_DIR/explicit-approval-gate.log"
CAPABILITY_LOG="$TMP_DIR/external-capability-detector.log"
DRIFT_PACKET="$TMP_DIR/environment-drift-replay.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$APPROVAL_LOG"
: > "$CAPABILITY_LOG"
: > "$DRIFT_PACKET"

for script in "$APPROVAL_GATE" "$CAPABILITY_DETECTOR"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-approval" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$APPROVAL_GATE" > "$APPROVAL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: approval gate packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: log=$APPROVAL_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-capability" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$CAPABILITY_DETECTOR" > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: log=$CAPABILITY_LOG" >&2
  exit 6
fi

required_approval_facts=(
  "route_classification=runtime_native_probe_explicit_approval_gate_packet"
  "approval_packet_created=true"
  "d3_runtime_native_probe_approval_required=true"
  "approved_runtime_native_probe_execution_admitted=false"
  "metal_capable_shell_does_not_imply_approval=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_approval_facts[@]}"; do
  if ! grep -F "$fact" "$APPROVAL_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: missing approval fact $fact" >&2
    exit 7
  fi
done

required_capability_facts=(
  "route_classification=runtime_native_probe_external_capability_detector"
  "external_handoff_classification_passed=true"
  "capability_packet_created=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_capability_facts[@]}"; do
  if ! grep -F "$fact" "$CAPABILITY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: missing capability fact $fact" >&2
    exit 8
  fi
done

approval_packet="$(grep -Eo 'approval_packet_path=[^[:space:]]+' "$APPROVAL_LOG" | tail -1 | cut -d= -f2-)"
capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$approval_packet" "$capability_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: missing packet $packet" >&2
    exit 9
  fi
done

approval_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
capability_smoke="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
approval_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
capability_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$capability_packet" | tail -1 | cut -d= -f2)"
approval_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$approval_packet" | tail -1 | cut -d= -f2)"
capability_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$capability_packet" | tail -1 | cut -d= -f2)"

environment_drift_between_probes="false"
if [[ "$approval_smoke" != "$capability_smoke" ||
  "$approval_failure_domain" != "$capability_failure_domain" ||
  "$approval_smoke_exit_code" != "$capability_smoke_exit_code" ]]; then
  environment_drift_between_probes="true"
fi

case "$approval_smoke" in
  automation_smoke_metal_capable|automation_smoke_metal_unavailable)
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: unexpected approval smoke classification $approval_smoke" >&2
    exit 10
    ;;
esac
case "$capability_smoke" in
  automation_smoke_metal_capable|automation_smoke_metal_unavailable)
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe environment drift replay: unexpected capability smoke classification $capability_smoke" >&2
    exit 11
    ;;
esac

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe environment drift replay: protected path modified" >&2
  exit 12
fi

{
  echo "environment_drift_replay_version=1"
  echo "approval_gate_packet_passed=true"
  echo "approval_log=$APPROVAL_LOG"
  echo "approval_packet=$approval_packet"
  echo "capability_detector_rerun_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "environment_drift_replay_passed=true"
  echo "approval_smoke_environment_classification=$approval_smoke"
  echo "capability_smoke_environment_classification=$capability_smoke"
  echo "approval_smoke_exit_code=$approval_smoke_exit_code"
  echo "capability_smoke_exit_code=$capability_smoke_exit_code"
  echo "approval_failure_domain=$approval_failure_domain"
  echo "capability_failure_domain=$capability_failure_domain"
  echo "environment_drift_between_probes=$environment_drift_between_probes"
  echo "metal_capable_shell_does_not_imply_approval=true"
  echo "required_next_actor=human_operator"
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
} > "$DRIFT_PACKET"

echo "cjgui renderer NSApplication runtime native probe environment drift replay: route_classification=runtime_native_probe_environment_drift_replay"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: approval_gate_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: capability_detector_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: environment_drift_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: drift_packet_path=$DRIFT_PACKET"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: approval_packet=$approval_packet"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: capability_packet=$capability_packet"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: approval_smoke_environment_classification=$approval_smoke"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: capability_smoke_environment_classification=$capability_smoke"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: environment_drift_between_probes=$environment_drift_between_probes"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe environment drift replay: renderer_state_write=false"
