#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 external packet promotion admission packet，并验证
# current shell 只能通过 shape admission，不能通过 external Metal-capable
# provenance admission，也不能解锁 renderer-state write。
# Truth: external packet promotion provenance classifier；不消费 D3 approval，
# 不执行 runtime native probe，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-promotion-provenance"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_packet.sh"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission.log"
PROVENANCE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-provenance.packet"
EXTERNAL_ADMISSION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$PROVENANCE_PACKET"

if [[ ! -x "$ADMISSION_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: missing executable script $ADMISSION_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_ADMISSION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: external admission packet missing $EXTERNAL_ADMISSION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_promotion_admission_packet_used=true"
    echo "promotion_admission_packet_path=$EXTERNAL_ADMISSION_PACKET"
    cat "$EXTERNAL_ADMISSION_PACKET"
  } > "$ADMISSION_LOG"
else
  SHORT_ADMISSION_TMP="/tmp/cjgui-stage99-promotion-provenance-admission-${$}"
  mkdir -p "$SHORT_ADMISSION_TMP"
  if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: promotion admission packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: log=$ADMISSION_LOG" >&2
    exit 6
  fi
fi

admission_packet="${EXTERNAL_ADMISSION_PACKET:-$(grep -Eo 'promotion_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: missing promotion admission packet $admission_packet" >&2
  exit 7
fi

required_admission_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  "external_validated_packet_shape_admitted=true"
  "external_metal_capable_packet_provenance_required=true"
  "automation_default_approval_consumption_denied=true"
  "current_shell_external_validated_packet_present=false"
  "current_shell_packet_promotion_denied=true"
  "renderer_state_write_denial_carried_forward=true"
  "renderer_state_write_blocked_until_external_promotion=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: missing admission fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: protected path modified" >&2
  exit 9
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_promotion_provenance_packet_version=1"
  echo "promotion_admission_packet=$admission_packet"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  echo "external_validated_packet_shape_admitted=true"
  echo "current_shell_external_packet_provenance_valid=false"
  echo "current_shell_packet_promotion_denied=true"
  echo "external_metal_capable_packet_provenance_required=true"
  echo "external_validated_packet_promotion_requires_metal_capable_shell=true"
  echo "automation_default_packet_rejected_for_promotion=true"
  echo "automation_default_approval_consumption_denied=true"
  echo "external_provenance_before_renderer_state_write_required=true"
  echo "renderer_state_write_blocked_until_external_provenance=true"
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
} > "$PROVENANCE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: route_classification=d3_result_envelope_renderer_state_external_packet_promotion_provenance"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: provenance_packet_path=$PROVENANCE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: promotion_admission_packet=$admission_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: current_shell_external_packet_provenance_valid=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: packet_promotion_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: renderer_state_write_blocked_until_external_provenance=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion provenance classifier: human_approved_d3_execution_consumed=false"
