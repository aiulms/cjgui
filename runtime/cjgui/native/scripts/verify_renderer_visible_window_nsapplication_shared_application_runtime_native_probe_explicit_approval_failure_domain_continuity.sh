#!/usr/bin/env zsh
#
# 维护注释：本脚本重跑 environment drift replay，并把 Metal-capable 与
# Metal-unavailable 两类 automation shell 输出归一为 continuity packet，确认它们
# 都不会自动消费 D3 approval。
# Truth: environment / failure-domain classification 后续路线；不执行 runtime
# native probe，不消费 D3 approval，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-failure-continuity"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
DRIFT_REPLAY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_environment_drift_replay.sh"
DRIFT_LOG="$TMP_DIR/environment-drift-replay.log"
CONTINUITY_PACKET="$TMP_DIR/explicit-approval-failure-domain-continuity.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$DRIFT_LOG"
: > "$CONTINUITY_PACKET"

if [[ ! -x "$DRIFT_REPLAY" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: missing executable drift replay $DRIFT_REPLAY" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-drift" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$DRIFT_REPLAY" > "$DRIFT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: environment drift replay failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: log=$DRIFT_LOG" >&2
  exit 5
fi

required_drift_facts=(
  "route_classification=runtime_native_probe_environment_drift_replay"
  "approval_gate_packet_passed=true"
  "capability_detector_rerun_passed=true"
  "environment_drift_replay_passed=true"
  "metal_capable_shell_does_not_imply_approval=true"
  "required_next_actor=human_operator"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_drift_facts[@]}"; do
  if ! grep -F "$fact" "$DRIFT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: missing drift fact $fact" >&2
    exit 6
  fi
done

drift_packet="$(grep -Eo 'drift_packet_path=[^[:space:]]+' "$DRIFT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$drift_packet" || ! -f "$drift_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: missing drift packet" >&2
  exit 7
fi

approval_smoke="$(grep -Eo '^approval_smoke_environment_classification=[A-Za-z0-9_]+' "$drift_packet" | tail -1 | cut -d= -f2)"
capability_smoke="$(grep -Eo '^capability_smoke_environment_classification=[A-Za-z0-9_]+' "$drift_packet" | tail -1 | cut -d= -f2)"
approval_exit_code="$(grep -Eo '^approval_smoke_exit_code=[0-9]+' "$drift_packet" | tail -1 | cut -d= -f2)"
capability_exit_code="$(grep -Eo '^capability_smoke_exit_code=[0-9]+' "$drift_packet" | tail -1 | cut -d= -f2)"
approval_failure_domain="$(grep -Eo '^approval_failure_domain=[A-Za-z0-9_]+' "$drift_packet" | tail -1 | cut -d= -f2)"
capability_failure_domain="$(grep -Eo '^capability_failure_domain=[A-Za-z0-9_]+' "$drift_packet" | tail -1 | cut -d= -f2)"
environment_drift_between_probes="$(grep -Eo '^environment_drift_between_probes=(true|false)' "$drift_packet" | tail -1 | cut -d= -f2)"

for classification in "$approval_smoke" "$capability_smoke"; do
  case "$classification" in
    automation_smoke_metal_capable|automation_smoke_metal_unavailable)
      ;;
    *)
      echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: unexpected smoke classification $classification" >&2
      exit 8
      ;;
  esac
done

if [[ "$approval_smoke" == "automation_smoke_metal_capable" &&
  ( "$approval_exit_code" != "0" || "$approval_failure_domain" != "none" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: inconsistent approval Metal-capable facts" >&2
  exit 9
fi
if [[ "$approval_smoke" == "automation_smoke_metal_unavailable" &&
  ( "$approval_exit_code" != "20" || "$approval_failure_domain" != "automation_environment" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: inconsistent approval Metal-unavailable facts" >&2
  exit 10
fi
if [[ "$capability_smoke" == "automation_smoke_metal_capable" &&
  ( "$capability_exit_code" != "0" || "$capability_failure_domain" != "none" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: inconsistent capability Metal-capable facts" >&2
  exit 11
fi
if [[ "$capability_smoke" == "automation_smoke_metal_unavailable" &&
  ( "$capability_exit_code" != "20" || "$capability_failure_domain" != "automation_environment" ) ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: inconsistent capability Metal-unavailable facts" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: protected path modified" >&2
  exit 13
fi

{
  echo "explicit_approval_failure_domain_continuity_version=1"
  echo "environment_drift_replay_passed=true"
  echo "drift_log=$DRIFT_LOG"
  echo "drift_packet=$drift_packet"
  echo "failure_domain_continuity_guard_passed=true"
  echo "approval_smoke_environment_classification=$approval_smoke"
  echo "capability_smoke_environment_classification=$capability_smoke"
  echo "approval_smoke_exit_code=$approval_exit_code"
  echo "capability_smoke_exit_code=$capability_exit_code"
  echo "approval_failure_domain=$approval_failure_domain"
  echo "capability_failure_domain=$capability_failure_domain"
  echo "environment_drift_between_probes=$environment_drift_between_probes"
  echo "allowed_environment_classification_set=metal_capable_or_metal_unavailable"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "d3_runtime_native_probe_approval_required=true"
  echo "metal_capable_shell_does_not_imply_approval=true"
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
} > "$CONTINUITY_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: route_classification=runtime_native_probe_explicit_approval_failure_domain_continuity"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: environment_drift_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: failure_domain_continuity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: continuity_packet_path=$CONTINUITY_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: drift_packet=$drift_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: approval_smoke_environment_classification=$approval_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: capability_smoke_environment_classification=$capability_smoke"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: environment_drift_between_probes=$environment_drift_between_probes"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: allowed_environment_classification_set=metal_capable_or_metal_unavailable"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: d3_runtime_native_probe_approval_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval failure-domain continuity: renderer_state_write=false"
