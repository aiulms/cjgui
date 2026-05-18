#!/usr/bin/env zsh
#
# 维护注释：本脚本为 D3 environment recovery 生成 bounded native packet。
# 它重跑当前 capability detector、stage93 replay checkpoint suite，并以禁用
# actual call 的方式编译运行 isolated accessor / throwaway native probes，确认
# 当前失败域是 Metal-unavailable environment，而不是 native probe harness failure。
# Truth: bounded native fail-closed packet；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-environment-recovery-native-packet"
CAPABILITY_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh"
CHECKPOINT_SUITE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_suite.sh"
ISOLATED_ACCESSOR_PROBE="$SCRIPT_DIR/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh"
THROWAWAY_PROBE="$SCRIPT_DIR/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh"
CAPABILITY_LOG="$TMP_DIR/external-capability.log"
CHECKPOINT_LOG="$TMP_DIR/replay-checkpoint-suite.log"
ISOLATED_LOG="$TMP_DIR/isolated-accessor-disabled.log"
THROWAWAY_LOG="$TMP_DIR/throwaway-disabled.log"
NATIVE_PACKET="$TMP_DIR/d3-environment-recovery-native.packet"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$CAPABILITY_LOG"
: > "$CHECKPOINT_LOG"
: > "$ISOLATED_LOG"
: > "$THROWAWAY_LOG"
: > "$NATIVE_PACKET"

for script in "$CAPABILITY_SCRIPT" "$CHECKPOINT_SUITE" "$ISOLATED_ACCESSOR_PROBE" "$THROWAWAY_PROBE"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: current shell is recovery-only and must not consume D3 approval" >&2
  exit 4
fi

if ! (
  unset CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED
  env TMPDIR="$TMP_DIR/nested-capability" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$CAPABILITY_SCRIPT"
) > "$CAPABILITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: capability detector failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: log=$CAPABILITY_LOG" >&2
  exit 5
fi

required_capability_facts=(
  "route_classification=runtime_native_probe_external_capability_detector"
  "external_handoff_classification_passed=true"
  "capability_packet_created=true"
  "smoke_exit_code=20"
  "smoke_environment_classification=automation_smoke_metal_unavailable"
  "failure_domain=automation_environment"
  "code_failure_domain=false"
  "external_handoff_required=true"
  "external_metal_capable_shell_required=true"
  "automation_environment_blocker_reconfirmed=true"
  "metal_capable_shell_observed=false"
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
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing capability fact $fact" >&2
    exit 6
  fi
done

if ! (
  unset CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED
  env TMPDIR="$TMP_DIR/nested-checkpoint" zsh "$CHECKPOINT_SUITE"
) > "$CHECKPOINT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: replay checkpoint suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: log=$CHECKPOINT_LOG" >&2
  exit 7
fi

required_checkpoint_facts=(
  "explicit_approval_replay_checkpoint_suite_passed=true"
  "replay_checkpoint_packet_ready=true"
  "replay_checkpoint_failure_domain_classifier_passed=true"
  "source_build_checkpoint_guard_passed=true"
  "failure_domain=none"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_checkpoint_facts[@]}"; do
  if ! grep -F "$fact" "$CHECKPOINT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing checkpoint fact $fact" >&2
    exit 8
  fi
done

set +e
env \
  CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" \
  CJGUI_NSAPP_SHARED_APPLICATION_ISOLATED_PROBE_ALLOW_ACTUAL_CALL=0 \
  zsh "$ISOLATED_ACCESSOR_PROBE" > "$ISOLATED_LOG" 2>&1
isolated_exit_code="$?"
set -e
if [[ "$isolated_exit_code" != "1" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: isolated accessor disabled probe returned $isolated_exit_code" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: log=$ISOLATED_LOG" >&2
  exit 9
fi

required_isolated_facts=(
  "actual_call_allowed=false"
  "main_thread_gate_preserved=true"
  "accessor_call_attempted=false"
  "accessor_returned_nonnull=false"
  "application_created=false"
  "classification=-102"
  "side_effect_classification=fail_closed_actual_call_disabled"
  "integer_classification_only=true"
  "dehydrated_facts_only=true"
  "probe_success=false"
)
for fact in "${required_isolated_facts[@]}"; do
  if ! grep -F "$fact" "$ISOLATED_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing isolated accessor fact $fact" >&2
    exit 10
  fi
done

set +e
env \
  CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" \
  CJGUI_NSAPP_SHARED_APPLICATION_THROWAWAY_PROBE_ALLOW_ACTUAL_CALL=0 \
  zsh "$THROWAWAY_PROBE" > "$THROWAWAY_LOG" 2>&1
throwaway_exit_code="$?"
set -e
if [[ "$throwaway_exit_code" != "1" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: throwaway disabled probe returned $throwaway_exit_code" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: log=$THROWAWAY_LOG" >&2
  exit 11
fi

required_throwaway_facts=(
  "actual_call_allowed=false"
  "main_thread_confined=true"
  "accessor_call_attempted=false"
  "accessor_returned_nonnull=false"
  "singleton_exists_after=false"
  "throwaway_application_created=false"
  "classification=-102"
  "side_effect_classification=fail_closed_actual_call_disabled"
  "throwaway_creation_evidence=false"
  "production_singleton_ownership_truth=false"
  "integer_classification_only=true"
  "dehydrated_facts_only=true"
  "probe_success=false"
)
for fact in "${required_throwaway_facts[@]}"; do
  if ! grep -F "$fact" "$THROWAWAY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing throwaway fact $fact" >&2
    exit 12
  fi
done

capability_packet="$(grep -Eo 'capability_packet_path=[^[:space:]]+' "$CAPABILITY_LOG" | tail -1 | cut -d= -f2-)"
checkpoint_suite_packet="$(grep -Eo 'replay_checkpoint_suite_packet_path=[^[:space:]]+' "$CHECKPOINT_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$capability_packet" "$checkpoint_suite_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: missing packet $packet" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: protected path modified" >&2
  exit 14
fi

{
  echo "d3_environment_recovery_native_packet_version=1"
  echo "capability_detector_passed=true"
  echo "capability_log=$CAPABILITY_LOG"
  echo "capability_packet=$capability_packet"
  echo "smoke_exit_code=20"
  echo "smoke_environment_classification=automation_smoke_metal_unavailable"
  echo "failure_domain=automation_environment"
  echo "external_metal_capable_shell_required=true"
  echo "metal_capable_shell_observed=false"
  echo "stage93_replay_checkpoint_suite_passed=true"
  echo "replay_checkpoint_suite_log=$CHECKPOINT_LOG"
  echo "replay_checkpoint_suite_packet=$checkpoint_suite_packet"
  echo "isolated_accessor_disabled_probe_compiled=true"
  echo "isolated_accessor_disabled_probe_exit_code=$isolated_exit_code"
  echo "isolated_accessor_disabled_fail_closed=true"
  echo "isolated_accessor_log=$ISOLATED_LOG"
  echo "throwaway_creation_disabled_probe_compiled=true"
  echo "throwaway_creation_disabled_probe_exit_code=$throwaway_exit_code"
  echo "throwaway_creation_disabled_fail_closed=true"
  echo "throwaway_log=$THROWAWAY_LOG"
  echo "bounded_native_fail_closed_packet_ready=true"
  echo "d3_limited_approval_available_but_unconsumed=true"
  echo "recovery_route_switch_required=true"
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
} > "$NATIVE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: route_classification=d3_environment_recovery_native_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: capability_detector_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: stage93_replay_checkpoint_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: isolated_accessor_disabled_fail_closed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: throwaway_creation_disabled_fail_closed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: bounded_native_fail_closed_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: native_packet_path=$NATIVE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: capability_packet=$capability_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: replay_checkpoint_suite_packet=$checkpoint_suite_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: smoke_exit_code=20"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: smoke_environment_classification=automation_smoke_metal_unavailable"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: failure_domain=automation_environment"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: external_metal_capable_shell_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: metal_capable_shell_observed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: d3_limited_approval_available_but_unconsumed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: recovery_route_switch_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery native packet: next_route=external_metal_capable_shell_d3_execution_or_recovery_packet_reuse"
