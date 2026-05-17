#!/usr/bin/env zsh
#
# 维护注释：本脚本为 runtime native-readiness non-D3 route 生成 explicit
# approval gate packet。它 fresh rerun stage88 maintenance aggregate guard，并把
# Metal-capable shell 与 explicit D3 approval gate 分开。
# Truth: capability detector / handoff contract；不执行 runtime native probe，不消费
# D3 approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-gate"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
AGGREGATE_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_maintenance_aggregate_guard.sh"
AGGREGATE_LOG="$TMP_DIR/non-d3-maintenance-aggregate.log"
APPROVAL_PACKET="$TMP_DIR/explicit-approval-gate.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$AGGREGATE_LOG"
: > "$APPROVAL_PACKET"

if [[ ! -x "$AGGREGATE_GUARD" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: missing executable aggregate guard $AGGREGATE_GUARD" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-aggregate" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$AGGREGATE_GUARD" > "$AGGREGATE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: aggregate guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: log=$AGGREGATE_LOG" >&2
  exit 5
fi

required_aggregate_facts=(
  "route_classification=runtime_native_probe_non_d3_maintenance_aggregate_guard"
  "orchestration_runner_passed=true"
  "protected_path_scan_passed=true"
  "public_foreign_surface_scan_passed=true"
  "production_native_bridge_forbidden_scan_passed=true"
  "non_d3_maintenance_aggregate_guard_passed=true"
  "code_failure_domain=false"
  "runtime_package_build_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "focused_regression_suite_rerun_passed=true"
  "anchored_packet_integrity_guard_passed=true"
  "failure_domain_replay_passed=true"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_aggregate_facts[@]}"; do
  if ! grep -F "$fact" "$AGGREGATE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: missing aggregate fact $fact" >&2
    exit 6
  fi
done

aggregate_packet="$(grep -Eo 'aggregate_packet_path=[^[:space:]]+' "$AGGREGATE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$aggregate_packet" || ! -f "$aggregate_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: missing aggregate packet" >&2
  exit 7
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$aggregate_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$aggregate_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$aggregate_packet" | tail -1 | cut -d= -f2)"
required_shell="$(grep -Eo '^required_shell=[A-Za-z0-9_]+' "$aggregate_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="false"

case "$smoke_classification" in
  automation_smoke_metal_capable)
    if [[ "$smoke_exit_code" != "0" || "$failure_domain" != "none" ]]; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: inconsistent Metal-capable facts" >&2
      exit 8
    fi
    metal_capable_shell_observed="true"
    ;;
  automation_smoke_metal_unavailable)
    if [[ "$smoke_exit_code" != "20" || "$failure_domain" != "automation_environment" ]]; then
      echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: inconsistent Metal-unavailable facts" >&2
      exit 9
    fi
    ;;
  *)
    echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: unexpected smoke classification $smoke_classification" >&2
    exit 10
    ;;
esac

d3_approval_env_present="false"
if [[ -n "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" ]]; then
  d3_approval_env_present="true"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: protected path modified" >&2
  exit 11
fi

{
  echo "explicit_approval_gate_packet_version=1"
  echo "aggregate_guard_passed=true"
  echo "aggregate_log=$AGGREGATE_LOG"
  echo "aggregate_packet=$aggregate_packet"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "required_shell=${required_shell:-explicitly_approved_shell}"
  echo "required_next_actor=human_operator"
  echo "d3_runtime_native_probe_approval_required=true"
  echo "d3_approval_env_present=$d3_approval_env_present"
  echo "d3_approval_env_true=false"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
  echo "code_failure_domain=false"
  echo "runtime_package_build_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "focused_regression_suite_rerun_passed=true"
  echo "anchored_packet_integrity_guard_passed=true"
  echo "failure_domain_replay_passed=true"
  echo "non_d3_maintenance_aggregate_guard_passed=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$APPROVAL_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: route_classification=runtime_native_probe_explicit_approval_gate_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: aggregate_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: approval_packet_created=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: approval_packet_path=$APPROVAL_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: aggregate_packet=$aggregate_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: required_shell=${required_shell:-explicitly_approved_shell}"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: d3_runtime_native_probe_approval_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: d3_approval_env_present=$d3_approval_env_present"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: d3_approval_env_true=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: approved_runtime_native_probe_execution_admitted=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval gate packet: renderer_state_write=false"
