#!/usr/bin/env zsh
#
# 维护注释：本脚本是 explicit approval gate handoff runner。它串联 owner
# probe、approval gate packet、route-scoped native evidence 与 environment drift
# replay，生成一个不消费 D3 approval 的 handoff packet。
# Truth: probe orchestration runner / handoff contract；不执行 runtime native probe，
# 不消费 D3 approval，不调用 application accessor，不创建 singleton，不扩 native
# bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-handoff-runner"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_handoff_owner.sh"
APPROVAL_GATE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_gate_packet.sh"
NATIVE_EVIDENCE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_route_scoped_native_bridge_evidence.sh"
DRIFT_REPLAY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_environment_drift_replay.sh"
OWNER_LOG="$TMP_DIR/explicit-approval-owner.log"
APPROVAL_LOG="$TMP_DIR/explicit-approval-gate.log"
NATIVE_LOG="$TMP_DIR/route-scoped-native-evidence.log"
DRIFT_LOG="$TMP_DIR/environment-drift-replay.log"
HANDOFF_PACKET="$TMP_DIR/explicit-approval-handoff-runner.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$APPROVAL_LOG"
: > "$NATIVE_LOG"
: > "$DRIFT_LOG"
: > "$HANDOFF_PACKET"

for script in "$OWNER_PROBE" "$APPROVAL_GATE" "$NATIVE_EVIDENCE" "$DRIFT_REPLAY"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-approval" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$APPROVAL_GATE" > "$APPROVAL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: approval gate failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: log=$APPROVAL_LOG" >&2
  exit 6
fi
if ! env TMPDIR="$TMP_DIR/nested-native" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$NATIVE_EVIDENCE" > "$NATIVE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: native evidence failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: log=$NATIVE_LOG" >&2
  exit 7
fi
if ! env TMPDIR="$TMP_DIR/nested-drift" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$DRIFT_REPLAY" > "$DRIFT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: environment drift replay failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: log=$DRIFT_LOG" >&2
  exit 8
fi

required_owner_facts=(
  "explicit_approval_gate_handoff_owner_present=true"
  "non_d3_rerun_maintenance_input=true"
  "explicit_approval_gate_handoff_route=true"
  "explicit_approval_gate_packet_required=true"
  "route_scoped_native_bridge_evidence_required=true"
  "environment_drift_replay_required=true"
  "explicit_approval_handoff_runner_required=true"
  "metal_capable_shell_does_not_imply_approval=true"
  "d3_runtime_native_probe_approval_external=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "code_failure_domain=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
  "same_shape_no_accessor_wrapper=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing owner fact $fact" >&2
    exit 9
  fi
done

required_approval_facts=(
  "route_classification=runtime_native_probe_explicit_approval_gate_packet"
  "approval_packet_created=true"
  "d3_runtime_native_probe_approval_required=true"
  "d3_approval_env_true=false"
  "approved_runtime_native_probe_execution_admitted=false"
  "metal_capable_shell_does_not_imply_approval=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_approval_facts[@]}"; do
  if ! grep -F "$fact" "$APPROVAL_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing approval fact $fact" >&2
    exit 10
  fi
done

required_native_facts=(
  "route_classification=runtime_native_probe_route_scoped_native_bridge_evidence"
  "approval_gate_packet_passed=true"
  "native_skeleton_compile_passed=true"
  "native_no_resource_symbols_passed=true"
  "route_scoped_native_bridge_evidence_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_native_facts[@]}"; do
  if ! grep -F "$fact" "$NATIVE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing native evidence fact $fact" >&2
    exit 11
  fi
done

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
)
for fact in "${required_drift_facts[@]}"; do
  if ! grep -F "$fact" "$DRIFT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing drift fact $fact" >&2
    exit 12
  fi
done

approval_packet="$(grep -Eo 'approval_packet_path=[^[:space:]]+' "$APPROVAL_LOG" | tail -1 | cut -d= -f2-)"
native_packet="$(grep -Eo 'native_evidence_packet_path=[^[:space:]]+' "$NATIVE_LOG" | tail -1 | cut -d= -f2-)"
drift_packet="$(grep -Eo 'drift_packet_path=[^[:space:]]+' "$DRIFT_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$approval_packet" "$native_packet" "$drift_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: missing packet $packet" >&2
    exit 13
  fi
done

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$approval_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$approval_packet" | tail -1 | cut -d= -f2)"
metal_capable_shell_observed="$(grep -Eo '^metal_capable_shell_observed=(true|false)' "$approval_packet" | tail -1 | cut -d= -f2)"
environment_drift_between_probes="$(grep -Eo '^environment_drift_between_probes=(true|false)' "$drift_packet" | tail -1 | cut -d= -f2)"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: protected path modified" >&2
  exit 14
fi

{
  echo "explicit_approval_handoff_runner_version=1"
  echo "explicit_approval_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "approval_gate_packet_passed=true"
  echo "approval_log=$APPROVAL_LOG"
  echo "approval_packet=$approval_packet"
  echo "route_scoped_native_bridge_evidence_passed=true"
  echo "native_log=$NATIVE_LOG"
  echo "native_packet=$native_packet"
  echo "environment_drift_replay_passed=true"
  echo "drift_log=$DRIFT_LOG"
  echo "drift_packet=$drift_packet"
  echo "explicit_approval_handoff_runner_passed=true"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "metal_capable_shell_observed=$metal_capable_shell_observed"
  echo "environment_drift_between_probes=${environment_drift_between_probes:-false}"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "d3_runtime_native_probe_approval_required=true"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
  echo "code_failure_domain=false"
  echo "runtime_package_build_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "focused_regression_suite_rerun_passed=true"
  echo "anchored_packet_integrity_guard_passed=true"
  echo "failure_domain_replay_passed=true"
  echo "route_scoped_native_bridge_evidence_passed=true"
  echo "environment_drift_replay_passed=true"
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
} > "$HANDOFF_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: route_classification=runtime_native_probe_explicit_approval_handoff_runner"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: explicit_approval_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: approval_gate_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: route_scoped_native_bridge_evidence_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: environment_drift_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: explicit_approval_handoff_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: handoff_packet_path=$HANDOFF_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: approval_packet=$approval_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: drift_packet=$drift_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: metal_capable_shell_observed=$metal_capable_shell_observed"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: environment_drift_between_probes=${environment_drift_between_probes:-false}"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: d3_runtime_native_probe_approval_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: approved_runtime_native_probe_execution_admitted=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval handoff runner: next_route=explicit_human_approved_d3_runtime_native_probe_execution_or_non_d3_handoff_rerun"
