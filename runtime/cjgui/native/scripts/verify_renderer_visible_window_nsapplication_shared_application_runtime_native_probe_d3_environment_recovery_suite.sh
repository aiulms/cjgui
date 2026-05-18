#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 environment recovery focused regression suite。
# 它串联 owner probe、bounded native packet、recovery classifier 与 source/build
# guard，确认当前 route 是 environment recovery 而不是 code failure。
# Truth: focused recovery suite；不消费 D3 approval，不执行 runtime native probe，不
# 调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-environment-recovery-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_owner.sh"
NATIVE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_native_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_environment_recovery_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-environment-recovery-owner.log"
NATIVE_LOG="$TMP_DIR/d3-environment-recovery-native.log"
CLASSIFIER_LOG="$TMP_DIR/d3-environment-recovery-classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-environment-recovery-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-environment-recovery-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$NATIVE_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$NATIVE_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: current shell is recovery-only and must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-native" zsh "$NATIVE_PACKET_SCRIPT" > "$NATIVE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: native packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: log=$NATIVE_LOG" >&2
  exit 6
fi

native_packet="$(grep -Eo 'native_packet_path=[^[:space:]]+' "$NATIVE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$native_packet" || ! -f "$native_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing native packet $native_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_ENVIRONMENT_RECOVERY_NATIVE_PACKET="$native_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: log=$CLASSIFIER_LOG" >&2
  exit 8
fi
if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_ENVIRONMENT_RECOVERY_NATIVE_PACKET="$native_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: log=$SOURCE_BUILD_LOG" >&2
  exit 9
fi

required_owner_facts=(
  "d3_environment_recovery_owner_present=true"
  "explicit_approval_replay_checkpoint_input=true"
  "current_shell_metal_unavailable=true"
  "failure_domain=automation_environment"
  "external_metal_capable_shell_required=true"
  "d3_limited_approval_unconsumed=true"
  "bounded_native_fail_closed_packet_required=true"
  "recovery_classifier_required=true"
  "source_build_recovery_guard_required=true"
  "focused_recovery_suite_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing owner fact $fact" >&2
    exit 10
  fi
done

required_native_facts=(
  "bounded_native_fail_closed_packet_ready=true"
  "capability_detector_passed=true"
  "stage93_replay_checkpoint_suite_passed=true"
  "isolated_accessor_disabled_fail_closed=true"
  "throwaway_creation_disabled_fail_closed=true"
  "failure_domain=automation_environment"
  "external_metal_capable_shell_required=true"
  "d3_limited_approval_available_but_unconsumed=true"
  "recovery_route_switch_required=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_native_facts[@]}"; do
  if ! grep -F "$fact" "$NATIVE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing native fact $fact" >&2
    exit 11
  fi
done

required_classifier_facts=(
  "d3_execution_precondition_met=false"
  "d3_execution_denied_by_current_environment=true"
  "d3_execution_failure_domain=automation_environment"
  "d3_execution_recovery_route_classified=true"
  "external_metal_capable_shell_required=true"
  "bounded_native_fail_closed_packet_reused=true"
  "stage93_replay_checkpoint_reused=true"
  "d3_limited_approval_available_but_unconsumed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing classifier fact $fact" >&2
    exit 12
  fi
done

required_source_facts=(
  "d3_environment_recovery_owner_probe_passed=true"
  "bounded_native_fail_closed_packet_ready=true"
  "d3_environment_recovery_classifier_passed=true"
  "runtime_package_build_passed=true"
  "source_build_recovery_guard_passed=true"
  "failure_domain=automation_environment"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing source/build fact $fact" >&2
    exit 13
  fi
done

classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$classifier_packet" "$source_build_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: missing packet $packet" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: protected path modified" >&2
  exit 15
fi

{
  echo "d3_environment_recovery_suite_version=1"
  echo "d3_environment_recovery_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "bounded_native_fail_closed_packet_ready=true"
  echo "native_log=$NATIVE_LOG"
  echo "native_packet=$native_packet"
  echo "d3_environment_recovery_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_recovery_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_environment_recovery_suite_passed=true"
  echo "failure_domain=automation_environment"
  echo "code_failure_domain=false"
  echo "external_metal_capable_shell_required=true"
  echo "metal_capable_shell_observed=false"
  echo "d3_limited_approval_available_but_unconsumed=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: route_classification=d3_environment_recovery_suite"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: d3_environment_recovery_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: bounded_native_fail_closed_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: d3_environment_recovery_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: source_build_recovery_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: d3_environment_recovery_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: native_packet=$native_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: source_build_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: failure_domain=automation_environment"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: external_metal_capable_shell_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: metal_capable_shell_observed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: d3_limited_approval_available_but_unconsumed=true"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe D3 environment recovery suite: next_route=external_metal_capable_shell_d3_execution_or_recovery_packet_reuse"
