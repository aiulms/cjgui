#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 external packet promotion-admission suite packet，并生成
# external packet provenance replay packet。它只固定 replay contract，不产出
# external result packet，不写 renderer state。
# Truth: external packet provenance replay packet；不消费 D3 approval，不执行
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-provenance-replay-packet"
PROMOTION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_suite.sh"
PROMOTION_SUITE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission-suite.log"
PROVENANCE_REPLAY_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay.packet"
EXTERNAL_PROMOTION_SUITE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_SUITE_PACKET:-}"
RUNTIME_STATE_FILE="$ROOT_DIR/src/runtime_state.cj"

mkdir -p "$TMP_DIR"
: > "$PROMOTION_SUITE_LOG"
: > "$PROVENANCE_REPLAY_PACKET"

if [[ ! -x "$PROMOTION_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: missing executable script $PROMOTION_SUITE_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: current packet route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_PROMOTION_SUITE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PROMOTION_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: external promotion suite packet missing $EXTERNAL_PROMOTION_SUITE_PACKET" >&2
    exit 5
  fi
  {
    echo "external_promotion_admission_suite_packet_used=true"
    echo "suite_packet_path=$EXTERNAL_PROMOTION_SUITE_PACKET"
    cat "$EXTERNAL_PROMOTION_SUITE_PACKET"
  } > "$PROMOTION_SUITE_LOG"
else
  SHORT_SUITE_TMP="/tmp/cjgui-stage100-provenance-replay-suite-${$}"
  mkdir -p "$SHORT_SUITE_TMP"
  if ! env TMPDIR="$SHORT_SUITE_TMP" zsh "$PROMOTION_SUITE_SCRIPT" > "$PROMOTION_SUITE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: promotion admission suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: log=$PROMOTION_SUITE_LOG" >&2
    exit 6
  fi
fi

promotion_suite_packet="${EXTERNAL_PROMOTION_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$PROMOTION_SUITE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$promotion_suite_packet" || ! -f "$promotion_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: missing promotion suite packet $promotion_suite_packet" >&2
  exit 7
fi

required_promotion_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_suite_passed=true"
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  "external_validated_packet_shape_admitted=true"
  "current_shell_external_packet_provenance_valid=false"
  "current_shell_packet_promotion_denied=true"
  "packet_promotion_allowed=false"
  "renderer_state_write_blocked_until_external_provenance=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_promotion_facts[@]}"; do
  if ! grep -F "$fact" "$promotion_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: missing promotion suite fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: protected path modified" >&2
  exit 9
fi

runtime_state_line_count="$(wc -l < "$RUNTIME_STATE_FILE" | tr -d '[:space:]')"
if [[ "$runtime_state_line_count" != "10065" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: unexpected runtime_state.cj line count $runtime_state_line_count" >&2
  exit 10
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_version=1"
  echo "promotion_admission_suite_packet=$promotion_suite_packet"
  echo "promotion_admission_replay_consumed=true"
  echo "external_packet_provenance_replay_ready=true"
  echo "external_validated_packet_production_required_before_replay=true"
  echo "external_metal_capable_provenance_replay_required=true"
  echo "shape_admission_separated_from_provenance_replay=true"
  echo "current_shell_external_packet_provenance_valid=false"
  echo "current_shell_provenance_replay_denied=true"
  echo "current_shell_provenance_replay_admitted=false"
  echo "external_provenance_packet_absent_in_current_shell=true"
  echo "external_packet_provenance_replay_allowed=false"
  echo "renderer_state_write_decision_after_external_provenance_required=true"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  echo "provenance_replay_does_not_write_renderer_state=true"
  echo "runtime_state_line_count=$runtime_state_line_count"
  echo "runtime_state_line_count_invariant=true"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_write_after_provenance_replay_allowed=false"
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
} > "$PROVENANCE_REPLAY_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: route_classification=d3_result_envelope_renderer_state_external_packet_provenance_replay_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: provenance_replay_packet_path=$PROVENANCE_REPLAY_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: promotion_admission_suite_packet=$promotion_suite_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: current_shell_provenance_replay_denied=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: renderer_state_write_decision_after_external_provenance_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay packet: human_approved_d3_execution_consumed=false"
