#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 promotion admission packet 与 provenance packet，
# 固定 external packet promotion admission 后的 renderer-state write gate。
# 它证明 promotion admission 仍不是 renderer-state write permission。
# Truth: external packet promotion write gate；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-promotion-write-gate"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_packet.sh"
PROVENANCE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier.sh"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission.log"
PROVENANCE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-provenance.log"
WRITE_GATE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-write-gate.packet"
EXTERNAL_ADMISSION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET:-}"
EXTERNAL_PROVENANCE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_PROVENANCE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$PROVENANCE_LOG"
: > "$WRITE_GATE_PACKET"

for script in "$ADMISSION_SCRIPT" "$PROVENANCE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: current write gate route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_ADMISSION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: external admission packet missing $EXTERNAL_ADMISSION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_promotion_admission_packet_used=true"
    echo "promotion_admission_packet_path=$EXTERNAL_ADMISSION_PACKET"
    cat "$EXTERNAL_ADMISSION_PACKET"
  } > "$ADMISSION_LOG"
else
  SHORT_ADMISSION_TMP="/tmp/cjgui-stage99-promotion-write-gate-admission-${$}"
  mkdir -p "$SHORT_ADMISSION_TMP"
  if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: promotion admission packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: log=$ADMISSION_LOG" >&2
    exit 6
  fi
fi

admission_packet="${EXTERNAL_ADMISSION_PACKET:-$(grep -Eo 'promotion_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: missing promotion admission packet $admission_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_PROVENANCE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PROVENANCE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: external provenance packet missing $EXTERNAL_PROVENANCE_PACKET" >&2
    exit 8
  fi
  {
    echo "external_provenance_packet_used=true"
    echo "provenance_packet_path=$EXTERNAL_PROVENANCE_PACKET"
    cat "$EXTERNAL_PROVENANCE_PACKET"
  } > "$PROVENANCE_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-provenance" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET="$admission_packet" zsh "$PROVENANCE_SCRIPT" > "$PROVENANCE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: provenance classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: log=$PROVENANCE_LOG" >&2
    exit 9
  fi
fi

provenance_packet="${EXTERNAL_PROVENANCE_PACKET:-$(grep -Eo 'provenance_packet_path=[^[:space:]]+' "$PROVENANCE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$provenance_packet" || ! -f "$provenance_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: missing provenance packet $provenance_packet" >&2
  exit 10
fi

required_admission_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  "external_validated_packet_shape_admitted=true"
  "current_shell_packet_promotion_denied=true"
  "external_promotion_admission_does_not_write_renderer_state=true"
  "renderer_state_write_blocked_until_external_promotion=true"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: missing admission fact $fact" >&2
    exit 11
  fi
done

required_provenance_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  "current_shell_external_packet_provenance_valid=false"
  "external_provenance_before_renderer_state_write_required=true"
  "renderer_state_write_blocked_until_external_provenance=true"
  "packet_promotion_allowed=false"
)
for fact in "${required_provenance_facts[@]}"; do
  if ! grep -F "$fact" "$provenance_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: missing provenance fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: protected path modified" >&2
  exit 13
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_promotion_write_gate_packet_version=1"
  echo "promotion_admission_packet=$admission_packet"
  echo "provenance_packet=$provenance_packet"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
  echo "external_packet_promotion_admission_is_not_renderer_state_write=true"
  echo "renderer_state_write_after_promotion_admission_allowed=false"
  echo "renderer_state_write_requires_external_provenance_and_state_write_decision=true"
  echo "current_shell_packet_promotion_denied=true"
  echo "current_shell_external_packet_provenance_valid=false"
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
} > "$WRITE_GATE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: route_classification=d3_result_envelope_renderer_state_external_packet_promotion_write_gate"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: write_gate_packet_path=$WRITE_GATE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: promotion_admission_packet=$admission_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: provenance_packet=$provenance_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: renderer_state_write_after_promotion_admission_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion write gate: human_approved_d3_execution_consumed=false"
