#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 D3 result-envelope renderer-state planning packet，并验证
# transition descriptor 仍停在 no-write gate。它不写 renderer state。
# Truth: renderer-state transition no-write guard；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-transition-guard"
PLAN_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_plan_packet.sh"
PLAN_LOG="$TMP_DIR/d3-result-envelope-renderer-state-plan.log"
TRANSITION_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-transition-guard.packet"
EXTERNAL_PLAN_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PLAN_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PLAN_LOG"
: > "$TRANSITION_PACKET"

if [[ ! -x "$PLAN_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: missing executable plan script $PLAN_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: current guard route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_PLAN_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PLAN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: external plan packet missing $EXTERNAL_PLAN_PACKET" >&2
    exit 5
  fi
  {
    echo "external_plan_packet_used=true"
    echo "renderer_state_plan_packet_path=$EXTERNAL_PLAN_PACKET"
    cat "$EXTERNAL_PLAN_PACKET"
  } > "$PLAN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-plan" zsh "$PLAN_SCRIPT" > "$PLAN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: plan packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: log=$PLAN_LOG" >&2
    exit 6
  fi
fi

plan_packet="${EXTERNAL_PLAN_PACKET:-$(grep -Eo 'renderer_state_plan_packet_path=[^[:space:]]+' "$PLAN_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$plan_packet" || ! -f "$plan_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: missing plan packet $plan_packet" >&2
  exit 7
fi

required_plan_facts=(
  "d3_result_envelope_renderer_state_plan_packet_passed=true"
  "validated_packet_before_renderer_state_plan=true"
  "quarantined_packet_as_planning_input=true"
  "renderer_state_transition_descriptor_prepared=true"
  "renderer_state_transition_descriptor_mode=dehydrated_no_write"
  "no_write_gate_before_promotion_confirmed=true"
  "promotion_hold_until_external_validation_confirmed=true"
  "runtime_state_line_count_invariant=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_plan_facts[@]}"; do
  if ! grep -F "$fact" "$plan_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: missing plan fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: protected path modified" >&2
  exit 9
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' '*.sh' \
  | grep -E '^\+' \
  | grep -E 'renderer_state_write[=]true|runtime_state_write[=]true|backend_ready_truth[=]true|production_singleton_ownership_truth[=]true|packet_promotion_allowed[=]true' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: forbidden truth/write diff found" >&2
  exit 10
fi

{
  echo "d3_result_envelope_renderer_state_transition_guard_version=1"
  echo "renderer_state_plan_packet=$plan_packet"
  echo "renderer_state_transition_descriptor_validated=true"
  echo "renderer_state_transition_write_allowed=false"
  echo "renderer_state_write_gate_closed=true"
  echo "runtime_state_line_count_invariant=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "d3_result_envelope_renderer_state_transition_guard_passed=true"
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
} > "$TRANSITION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: route_classification=d3_result_envelope_renderer_state_transition_guard"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: d3_result_envelope_renderer_state_transition_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: transition_guard_packet_path=$TRANSITION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: renderer_state_plan_packet=$plan_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: renderer_state_transition_descriptor_validated=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: renderer_state_transition_write_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition guard: human_approved_d3_execution_consumed=false"
