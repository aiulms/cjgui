#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state transition admission packet，并验证
# 当前自动化 shell 下 transition write 必须继续被拒绝。
# Truth: transition write denial classifier；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-transition-write-denial"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_packet.sh"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission.log"
WRITE_DENIAL_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-transition-write-denial.packet"
EXTERNAL_ADMISSION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$WRITE_DENIAL_PACKET"

if [[ ! -x "$ADMISSION_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: missing executable script $ADMISSION_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_ADMISSION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: external admission packet missing $EXTERNAL_ADMISSION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_admission_packet_used=true"
    echo "transition_admission_packet_path=$EXTERNAL_ADMISSION_PACKET"
    cat "$EXTERNAL_ADMISSION_PACKET"
  } > "$ADMISSION_LOG"
else
  SHORT_ADMISSION_TMP="/tmp/cjgui-stage98-transition-admission-${$}"
  mkdir -p "$SHORT_ADMISSION_TMP"
  if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: admission packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: log=$ADMISSION_LOG" >&2
    exit 6
  fi
fi

admission_packet="${EXTERNAL_ADMISSION_PACKET:-$(grep -Eo 'transition_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: missing admission packet $admission_packet" >&2
  exit 7
fi

required_admission_facts=(
  "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  "dehydrated_renderer_state_transition_candidate_admitted=true"
  "renderer_state_transition_write_admitted=false"
  "renderer_state_transition_write_denied=true"
  "external_validated_packet_before_transition_write_required=true"
  "promotion_quarantine_carry_forward=true"
  "no_write_admission_until_promotion=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: missing admission fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: protected path modified" >&2
  exit 9
fi

{
  echo "d3_result_envelope_renderer_state_transition_write_denial_packet_version=1"
  echo "transition_admission_packet=$admission_packet"
  echo "d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
  echo "dehydrated_renderer_state_transition_candidate_admitted=true"
  echo "renderer_state_transition_write_admitted=false"
  echo "renderer_state_transition_write_denied=true"
  echo "renderer_state_write_blocked_by_admission=true"
  echo "external_validated_packet_before_transition_write_required=true"
  echo "automation_default_packet_cannot_unlock_renderer_state_write=true"
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
} > "$WRITE_DENIAL_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: route_classification=d3_result_envelope_renderer_state_transition_write_denial"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: write_denial_packet_path=$WRITE_DENIAL_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: transition_admission_packet=$admission_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: renderer_state_transition_write_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: renderer_state_write_blocked_by_admission=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: automation_default_packet_cannot_unlock_renderer_state_write=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition write denial classifier: human_approved_d3_execution_consumed=false"
