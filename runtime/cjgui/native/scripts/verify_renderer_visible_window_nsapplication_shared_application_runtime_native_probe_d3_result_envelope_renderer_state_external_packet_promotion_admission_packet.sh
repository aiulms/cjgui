#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state transition external packet handoff
# packet，生成 external validated packet promotion admission packet。它只承认
# external validated packet 的 shape / provenance admission，不 promotion，不写
# renderer state。
# Truth: external packet promotion admission packet；不消费 D3 approval，不执行
# runtime native probe，不调用 application accessor，不创建 singleton，不扩
# native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-promotion-admission-packet"
HANDOFF_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_external_packet_handoff.sh"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-external-handoff.log"
PROMOTION_ADMISSION_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission.packet"
EXTERNAL_HANDOFF_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_EXTERNAL_HANDOFF_PACKET:-}"
RUNTIME_STATE_FILE="$ROOT_DIR/src/runtime_state.cj"

mkdir -p "$TMP_DIR"
: > "$HANDOFF_LOG"
: > "$PROMOTION_ADMISSION_PACKET"

if [[ ! -x "$HANDOFF_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: missing executable script $HANDOFF_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: current packet route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_HANDOFF_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_HANDOFF_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: external handoff packet missing $EXTERNAL_HANDOFF_PACKET" >&2
    exit 5
  fi
  {
    echo "external_handoff_packet_used=true"
    echo "external_packet_handoff_packet_path=$EXTERNAL_HANDOFF_PACKET"
    cat "$EXTERNAL_HANDOFF_PACKET"
  } > "$HANDOFF_LOG"
else
  SHORT_HANDOFF_TMP="/tmp/cjgui-stage99-promotion-admission-handoff-${$}"
  mkdir -p "$SHORT_HANDOFF_TMP"
  if ! env TMPDIR="$SHORT_HANDOFF_TMP" zsh "$HANDOFF_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: handoff packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: log=$HANDOFF_LOG" >&2
    exit 6
  fi
fi

handoff_packet="${EXTERNAL_HANDOFF_PACKET:-$(grep -Eo 'external_packet_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: missing handoff packet $handoff_packet" >&2
  exit 7
fi

required_handoff_facts=(
  "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  "external_validated_packet_still_required=true"
  "external_validated_packet_must_be_metal_capable=true"
  "external_validated_packet_must_not_consume_automation_default_approval=true"
  "automation_default_packet_cannot_unlock_renderer_state_write=true"
  "renderer_state_write_blocked_by_admission=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$handoff_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: missing handoff fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: protected path modified" >&2
  exit 9
fi

runtime_state_line_count="$(wc -l < "$RUNTIME_STATE_FILE" | tr -d '[:space:]')"
if [[ "$runtime_state_line_count" != "10065" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: unexpected runtime_state.cj line count $runtime_state_line_count" >&2
  exit 10
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_version=1"
  echo "transition_external_handoff_packet=$handoff_packet"
  echo "transition_external_packet_handoff_consumed=true"
  echo "external_validated_packet_shape_admitted=true"
  echo "external_metal_capable_packet_provenance_required=true"
  echo "external_validated_packet_must_not_consume_automation_default_approval=true"
  echo "automation_default_approval_consumption_denied=true"
  echo "automation_default_packet_cannot_unlock_renderer_state_write=true"
  echo "current_shell_external_validated_packet_present=false"
  echo "current_shell_packet_promotion_denied=true"
  echo "future_external_validated_packet_schema_admitted=true"
  echo "result_envelope_schema_continuity_required=true"
  echo "transition_admission_audit_continuity_required=true"
  echo "renderer_state_write_denial_carried_forward=true"
  echo "renderer_state_write_blocked_until_external_promotion=true"
  echo "external_promotion_admission_does_not_write_renderer_state=true"
  echo "runtime_state_line_count=$runtime_state_line_count"
  echo "runtime_state_line_count_invariant=true"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_transition_write_admitted=false"
  echo "renderer_state_write_blocked_by_admission=true"
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
} > "$PROMOTION_ADMISSION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: route_classification=d3_result_envelope_renderer_state_external_packet_promotion_admission_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: promotion_admission_packet_path=$PROMOTION_ADMISSION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: transition_external_handoff_packet=$handoff_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: external_validated_packet_shape_admitted=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: current_shell_packet_promotion_denied=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: renderer_state_write_blocked_until_external_promotion=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission packet: human_approved_d3_execution_consumed=false"
