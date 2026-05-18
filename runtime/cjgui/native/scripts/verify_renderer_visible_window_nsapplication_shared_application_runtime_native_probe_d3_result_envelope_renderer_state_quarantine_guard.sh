#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state plan packet 与 transition guard packet，
# 验证 quarantined D3 result-envelope 仍不能 promotion，也不能触发 renderer-state write。
# Truth: renderer-state planning quarantine guard；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-quarantine-guard"
PLAN_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_plan_packet.sh"
TRANSITION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_guard.sh"
PLAN_LOG="$TMP_DIR/d3-result-envelope-renderer-state-plan.log"
TRANSITION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition.log"
QUARANTINE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-quarantine-guard.packet"
EXTERNAL_PLAN_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET:-}"
EXTERNAL_TRANSITION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_GUARD_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PLAN_LOG"
: > "$TRANSITION_LOG"
: > "$QUARANTINE_PACKET"

for script in "$PLAN_SCRIPT" "$TRANSITION_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: current guard route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_PLAN_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PLAN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: external plan packet missing $EXTERNAL_PLAN_PACKET" >&2
    exit 5
  fi
  {
    echo "external_plan_packet_used=true"
    echo "renderer_state_plan_packet_path=$EXTERNAL_PLAN_PACKET"
    cat "$EXTERNAL_PLAN_PACKET"
  } > "$PLAN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-plan" zsh "$PLAN_SCRIPT" > "$PLAN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: plan packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: log=$PLAN_LOG" >&2
    exit 6
  fi
fi

plan_packet="${EXTERNAL_PLAN_PACKET:-$(grep -Eo 'renderer_state_plan_packet_path=[^[:space:]]+' "$PLAN_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$plan_packet" || ! -f "$plan_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: missing plan packet $plan_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_TRANSITION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_TRANSITION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: external transition packet missing $EXTERNAL_TRANSITION_PACKET" >&2
    exit 8
  fi
  {
    echo "external_transition_packet_used=true"
    echo "transition_guard_packet_path=$EXTERNAL_TRANSITION_PACKET"
    cat "$EXTERNAL_TRANSITION_PACKET"
  } > "$TRANSITION_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-transition" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET="$plan_packet" zsh "$TRANSITION_SCRIPT" > "$TRANSITION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: transition guard failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: log=$TRANSITION_LOG" >&2
    exit 9
  fi
fi

transition_packet="${EXTERNAL_TRANSITION_PACKET:-$(grep -Eo 'transition_guard_packet_path=[^[:space:]]+' "$TRANSITION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$transition_packet" || ! -f "$transition_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: missing transition packet $transition_packet" >&2
  exit 10
fi

required_plan_facts=(
  "d3_result_envelope_renderer_state_plan_packet_passed=true"
  "promotion_hold_until_external_validation_confirmed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "current_shell_promotion_rejected=true"
  "renderer_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_plan_facts[@]}"; do
  if ! grep -F "$fact" "$plan_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: missing plan fact $fact" >&2
    exit 11
  fi
done

required_transition_facts=(
  "d3_result_envelope_renderer_state_transition_guard_passed=true"
  "renderer_state_transition_write_allowed=false"
  "renderer_state_write_gate_closed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_transition_facts[@]}"; do
  if ! grep -F "$fact" "$transition_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: missing transition fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: protected path modified" >&2
  exit 13
fi

{
  echo "d3_result_envelope_renderer_state_quarantine_guard_version=1"
  echo "renderer_state_plan_packet=$plan_packet"
  echo "renderer_state_transition_guard_packet=$transition_packet"
  echo "d3_result_envelope_renderer_state_plan_packet_passed=true"
  echo "d3_result_envelope_renderer_state_transition_guard_passed=true"
  echo "renderer_state_quarantine_guard_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "promotion_hold_until_external_validation_confirmed=true"
  echo "external_validated_packet_still_required=true"
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
} > "$QUARANTINE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: route_classification=d3_result_envelope_renderer_state_quarantine_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: renderer_state_quarantine_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: quarantine_guard_packet_path=$QUARANTINE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: renderer_state_plan_packet=$plan_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: renderer_state_transition_guard_packet=$transition_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: packet_promotion_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: packet_promotion_quarantined=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: renderer_state_write_blocked_before_external_promotion=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state quarantine guard: human_approved_d3_execution_consumed=false"
