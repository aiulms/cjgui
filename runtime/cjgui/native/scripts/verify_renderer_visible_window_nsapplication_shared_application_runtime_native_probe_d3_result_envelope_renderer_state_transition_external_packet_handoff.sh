#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 transition admission packet 与 write denial packet，
# 固定 external packet handoff facts。它只描述下一步所需的外部验证包，不
# promotion，也不写 renderer state。
# Truth: transition external packet handoff；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-transition-external-handoff"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_packet.sh"
WRITE_DENIAL_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_write_denial_classifier.sh"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission.log"
WRITE_DENIAL_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-write-denial.log"
HANDOFF_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-transition-external-handoff.packet"
EXTERNAL_ADMISSION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET:-}"
EXTERNAL_WRITE_DENIAL_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_WRITE_DENIAL_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$WRITE_DENIAL_LOG"
: > "$HANDOFF_PACKET"

for script in "$ADMISSION_SCRIPT" "$WRITE_DENIAL_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: current handoff route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_ADMISSION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: external admission packet missing $EXTERNAL_ADMISSION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_admission_packet_used=true"
    echo "transition_admission_packet_path=$EXTERNAL_ADMISSION_PACKET"
    cat "$EXTERNAL_ADMISSION_PACKET"
  } > "$ADMISSION_LOG"
else
  SHORT_ADMISSION_TMP="/tmp/cjgui-stage98-transition-handoff-admission-${$}"
  mkdir -p "$SHORT_ADMISSION_TMP"
  if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: admission packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: log=$ADMISSION_LOG" >&2
    exit 6
  fi
fi

admission_packet="${EXTERNAL_ADMISSION_PACKET:-$(grep -Eo 'transition_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: missing admission packet $admission_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_WRITE_DENIAL_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_WRITE_DENIAL_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: external write denial packet missing $EXTERNAL_WRITE_DENIAL_PACKET" >&2
    exit 8
  fi
  {
    echo "external_write_denial_packet_used=true"
    echo "write_denial_packet_path=$EXTERNAL_WRITE_DENIAL_PACKET"
    cat "$EXTERNAL_WRITE_DENIAL_PACKET"
  } > "$WRITE_DENIAL_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-denial" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" zsh "$WRITE_DENIAL_SCRIPT" > "$WRITE_DENIAL_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: write denial classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: log=$WRITE_DENIAL_LOG" >&2
    exit 9
  fi
fi

write_denial_packet="${EXTERNAL_WRITE_DENIAL_PACKET:-$(grep -Eo 'write_denial_packet_path=[^[:space:]]+' "$WRITE_DENIAL_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$write_denial_packet" || ! -f "$write_denial_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: missing write denial packet $write_denial_packet" >&2
  exit 10
fi

required_admission_facts=(
  "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  "external_validated_packet_before_transition_write_required=true"
  "promotion_quarantine_carry_forward=true"
  "renderer_state_transition_write_admitted=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: missing admission fact $fact" >&2
    exit 11
  fi
done

required_denial_facts=(
  "d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
  "renderer_state_write_blocked_by_admission=true"
  "automation_default_packet_cannot_unlock_renderer_state_write=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_denial_facts[@]}"; do
  if ! grep -F "$fact" "$write_denial_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: missing denial fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: protected path modified" >&2
  exit 13
fi

{
  echo "d3_result_envelope_renderer_state_transition_external_packet_handoff_version=1"
  echo "transition_admission_packet=$admission_packet"
  echo "write_denial_packet=$write_denial_packet"
  echo "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  echo "external_validated_packet_still_required=true"
  echo "external_validated_packet_must_be_metal_capable=true"
  echo "external_validated_packet_must_not_consume_automation_default_approval=true"
  echo "automation_default_packet_cannot_unlock_renderer_state_write=true"
  echo "next_route=external_validated_packet_promotion_or_transition_admission_replay"
  echo "renderer_state_transition_write_admitted=false"
  echo "renderer_state_write_blocked_by_admission=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
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
} > "$HANDOFF_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: route_classification=d3_result_envelope_renderer_state_transition_external_packet_handoff"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: external_packet_handoff_packet_path=$HANDOFF_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: transition_admission_packet=$admission_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: write_denial_packet=$write_denial_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: external_validated_packet_still_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: renderer_state_write_blocked_by_admission=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition external packet handoff: human_approved_d3_execution_consumed=false"
