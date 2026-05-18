#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state planning focused
# regression suite。它串联 owner probe、plan packet、transition guard、
# quarantine guard 与 source/build guard。
# Truth: focused renderer-state planning suite；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-planning-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_planning_owner.sh"
PLAN_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_plan_packet.sh"
TRANSITION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_guard.sh"
QUARANTINE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_quarantine_guard.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_planning_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-planning-owner.log"
PLAN_LOG="$TMP_DIR/d3-result-envelope-renderer-state-plan.log"
TRANSITION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition.log"
QUARANTINE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-quarantine.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-planning-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PLAN_LOG"
: > "$TRANSITION_LOG"
: > "$QUARANTINE_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$PLAN_SCRIPT" "$TRANSITION_SCRIPT" "$QUARANTINE_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-plan" zsh "$PLAN_SCRIPT" > "$PLAN_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: plan packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: log=$PLAN_LOG" >&2
  exit 6
fi
plan_packet="$(grep -Eo 'renderer_state_plan_packet_path=[^[:space:]]+' "$PLAN_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$plan_packet" || ! -f "$plan_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing plan packet $plan_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-transition" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" zsh "$TRANSITION_SCRIPT" > "$TRANSITION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: transition guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: log=$TRANSITION_LOG" >&2
  exit 8
fi
transition_packet="$(grep -Eo 'transition_guard_packet_path=[^[:space:]]+' "$TRANSITION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$transition_packet" || ! -f "$transition_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing transition packet $transition_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-quarantine" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_GUARD_PACKET="$transition_packet" zsh "$QUARANTINE_SCRIPT" > "$QUARANTINE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: quarantine guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: log=$QUARANTINE_LOG" >&2
  exit 10
fi
quarantine_packet="$(grep -Eo 'quarantine_guard_packet_path=[^[:space:]]+' "$QUARANTINE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$quarantine_packet" || ! -f "$quarantine_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing quarantine packet $quarantine_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_planning_owner_present=true"
  "packet_validation_input=true"
  "renderer_state_transition_descriptor_required=true"
  "no_write_gate_before_promotion_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_plan_facts=(
  "d3_result_envelope_renderer_state_plan_packet_passed=true"
  "renderer_state_transition_descriptor_prepared=true"
  "no_write_gate_before_promotion_confirmed=true"
  "promotion_hold_until_external_validation_confirmed=true"
  "runtime_state_line_count_invariant=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_plan_facts[@]}"; do
  if ! grep -F "$fact" "$PLAN_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing plan fact $fact" >&2
    exit 15
  fi
done

required_transition_facts=(
  "d3_result_envelope_renderer_state_transition_guard_passed=true"
  "renderer_state_transition_write_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_transition_facts[@]}"; do
  if ! grep -F "$fact" "$TRANSITION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing transition fact $fact" >&2
    exit 16
  fi
done

required_quarantine_facts=(
  "renderer_state_quarantine_guard_passed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_write_blocked_before_external_promotion=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_quarantine_facts[@]}"; do
  if ! grep -F "$fact" "$QUARANTINE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing quarantine fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_planning_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_plan_packet_passed=true"
  "d3_result_envelope_renderer_state_transition_guard_passed=true"
  "renderer_state_quarantine_guard_passed=true"
  "runtime_package_build_passed=true"
  "source_build_renderer_state_planning_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_planning_suite_version=1"
  echo "d3_result_envelope_renderer_state_planning_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_plan_packet_passed=true"
  echo "plan_log=$PLAN_LOG"
  echo "renderer_state_plan_packet=$plan_packet"
  echo "d3_result_envelope_renderer_state_transition_guard_passed=true"
  echo "transition_log=$TRANSITION_LOG"
  echo "renderer_state_transition_guard_packet=$transition_packet"
  echo "renderer_state_quarantine_guard_passed=true"
  echo "quarantine_log=$QUARANTINE_LOG"
  echo "renderer_state_quarantine_guard_packet=$quarantine_packet"
  echo "source_build_renderer_state_planning_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_planning_suite_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_transition_write_allowed=false"
  echo "renderer_state_write_blocked_before_external_promotion=true"
  echo "failure_domain=automation_environment"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: route_classification=d3_result_envelope_renderer_state_planning_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: d3_result_envelope_renderer_state_planning_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: d3_result_envelope_renderer_state_plan_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: d3_result_envelope_renderer_state_transition_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: renderer_state_quarantine_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: source_build_renderer_state_planning_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: d3_result_envelope_renderer_state_planning_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state planning suite: human_approved_d3_execution_consumed=false"
