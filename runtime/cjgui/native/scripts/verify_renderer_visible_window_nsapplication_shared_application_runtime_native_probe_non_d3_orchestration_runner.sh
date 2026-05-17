#!/usr/bin/env zsh
#
# 维护注释：本脚本是 runtime native-readiness non-D3 rerun maintenance 的
# orchestration runner。它串联 owner probe、packet integrity guard 与
# failure-domain replay，提供一个 non-hard-boundary rerun entry。
# Truth: probe orchestration runner；不执行 runtime native probe，不消费 D3
# approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-non-d3-orchestration-runner"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_rerun_maintenance_owner.sh"
PACKET_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_packet_integrity_guard.sh"
FAILURE_REPLAY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_failure_domain_replay.sh"
OWNER_LOG="$TMP_DIR/non-d3-owner.log"
PACKET_LOG="$TMP_DIR/packet-integrity.log"
FAILURE_REPLAY_LOG="$TMP_DIR/failure-domain-replay.log"
ORCHESTRATION_PACKET="$TMP_DIR/non-d3-orchestration-runner.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$FAILURE_REPLAY_LOG"
: > "$ORCHESTRATION_PACKET"

for script in "$OWNER_PROBE" "$PACKET_GUARD" "$FAILURE_REPLAY"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: log=$OWNER_LOG" >&2
  exit 5
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$PACKET_GUARD" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: packet integrity guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: log=$PACKET_LOG" >&2
  exit 6
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$FAILURE_REPLAY" > "$FAILURE_REPLAY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: failure-domain replay failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: log=$FAILURE_REPLAY_LOG" >&2
  exit 7
fi

required_owner_facts=(
  "non_d3_rerun_maintenance_owner_present=true"
  "source_build_probe_evidence_input=true"
  "non_d3_rerun_maintenance_route=true"
  "fresh_focused_regression_suite_rerun_required=true"
  "anchored_packet_integrity_guard_required=true"
  "failure_domain_replay_required=true"
  "orchestration_runner_required=true"
  "maintenance_aggregate_guard_required=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
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
    echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: missing owner fact $fact" >&2
    exit 8
  fi
done

required_packet_facts=(
  "route_classification=runtime_native_probe_non_d3_packet_integrity_guard"
  "focused_regression_suite_rerun_passed=true"
  "anchored_packet_integrity_guard_passed=true"
  "runtime_package_build_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "failure_domain_matrix_aggregated=true"
  "related_regression_guards_aggregated=true"
  "automation_can_continue_non_d3_recovery=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_packet_facts[@]}"; do
  if ! grep -F "$fact" "$PACKET_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: missing packet fact $fact" >&2
    exit 9
  fi
done

required_replay_facts=(
  "route_classification=runtime_native_probe_non_d3_failure_domain_replay"
  "capability_detector_rerun_passed=true"
  "failure_domain_matrix_rerun_passed=true"
  "failure_domain_replay_passed=true"
  "next_actor=human_operator"
  "code_failure_domain=false"
  "automation_can_continue_non_d3_recovery=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_replay_facts[@]}"; do
  if ! grep -F "$fact" "$FAILURE_REPLAY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: missing replay fact $fact" >&2
    exit 10
  fi
done

packet_integrity_packet="$(grep -Eo 'packet_integrity_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
failure_replay_packet="$(grep -Eo 'failure_domain_replay_packet_path=[^[:space:]]+' "$FAILURE_REPLAY_LOG" | tail -1 | cut -d= -f2-)"

for packet in "$packet_integrity_packet" "$failure_replay_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: missing packet $packet" >&2
    exit 11
  fi
done

packet_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$packet_integrity_packet" | tail -1 | cut -d= -f2)"
replay_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$failure_replay_packet" | tail -1 | cut -d= -f2)"
packet_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$packet_integrity_packet" | tail -1 | cut -d= -f2)"
replay_failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$failure_replay_packet" | tail -1 | cut -d= -f2)"
packet_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$packet_integrity_packet" | tail -1 | cut -d= -f2)"
replay_smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$failure_replay_packet" | tail -1 | cut -d= -f2)"
required_shell="$(grep -Eo '^required_shell=[A-Za-z0-9_]+' "$failure_replay_packet" | tail -1 | cut -d= -f2)"

if [[ "$packet_smoke_classification" != "$replay_smoke_classification" ||
  "$packet_failure_domain" != "$replay_failure_domain" ||
  "$packet_smoke_exit_code" != "$replay_smoke_exit_code" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: packet guard and failure replay diverged" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: protected path modified" >&2
  exit 13
fi

{
  echo "non_d3_orchestration_runner_version=1"
  echo "non_d3_owner_probe_passed=true"
  echo "owner_probe_log=$OWNER_LOG"
  echo "packet_integrity_guard_passed=true"
  echo "packet_integrity_log=$PACKET_LOG"
  echo "packet_integrity_packet=$packet_integrity_packet"
  echo "failure_domain_replay_passed=true"
  echo "failure_domain_replay_log=$FAILURE_REPLAY_LOG"
  echo "failure_domain_replay_packet=$failure_replay_packet"
  echo "non_d3_orchestration_runner_passed=true"
  echo "smoke_exit_code=$packet_smoke_exit_code"
  echo "smoke_environment_classification=$packet_smoke_classification"
  echo "failure_domain=$packet_failure_domain"
  echo "required_shell=$required_shell"
  echo "code_failure_domain=false"
  echo "runtime_package_build_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "focused_regression_suite_rerun_passed=true"
  echo "anchored_packet_integrity_guard_passed=true"
  echo "failure_domain_replay_passed=true"
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
} > "$ORCHESTRATION_PACKET"

echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: route_classification=runtime_native_probe_non_d3_orchestration_runner"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: non_d3_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: packet_integrity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: failure_domain_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: non_d3_orchestration_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: orchestration_packet_path=$ORCHESTRATION_PACKET"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: packet_integrity_packet=$packet_integrity_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: failure_domain_replay_packet=$failure_replay_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: smoke_exit_code=$packet_smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: smoke_environment_classification=$packet_smoke_classification"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: failure_domain=$packet_failure_domain"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: required_shell=$required_shell"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: source_build_probe_evidence_strengthened=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: focused_regression_suite_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: anchored_packet_integrity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 orchestration runner: renderer_state_write=false"
