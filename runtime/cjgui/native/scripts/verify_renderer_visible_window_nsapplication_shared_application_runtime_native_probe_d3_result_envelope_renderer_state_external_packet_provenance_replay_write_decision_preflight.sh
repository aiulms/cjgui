#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 provenance replay packet 与 classifier packet，并验证
# external provenance replay 即使完成也不是 renderer-state write permission；
# renderer-state write 仍需要单独 decision。
# Truth: provenance replay write-decision preflight；不消费 D3 approval，不执行
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-provenance-replay-write-decision-preflight"
REPLAY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier.sh"
REPLAY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-classifier.log"
WRITE_DECISION_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-write-decision-preflight.packet"
EXTERNAL_REPLAY_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET:-}"
EXTERNAL_CLASSIFIER_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_CLASSIFIER_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$REPLAY_LOG"
: > "$CLASSIFIER_LOG"
: > "$WRITE_DECISION_PACKET"

for script in "$REPLAY_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: current preflight route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_REPLAY_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_REPLAY_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: external replay packet missing $EXTERNAL_REPLAY_PACKET" >&2
    exit 5
  fi
  {
    echo "external_provenance_replay_packet_used=true"
    echo "provenance_replay_packet_path=$EXTERNAL_REPLAY_PACKET"
    cat "$EXTERNAL_REPLAY_PACKET"
  } > "$REPLAY_LOG"
else
  SHORT_REPLAY_TMP="/tmp/cjgui-stage100-write-decision-replay-${$}"
  mkdir -p "$SHORT_REPLAY_TMP"
  if ! env TMPDIR="$SHORT_REPLAY_TMP" zsh "$REPLAY_PACKET_SCRIPT" > "$REPLAY_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: provenance replay packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: log=$REPLAY_LOG" >&2
    exit 6
  fi
fi

replay_packet="${EXTERNAL_REPLAY_PACKET:-$(grep -Eo 'provenance_replay_packet_path=[^[:space:]]+' "$REPLAY_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$replay_packet" || ! -f "$replay_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: missing provenance replay packet $replay_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_CLASSIFIER_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: external classifier packet missing $EXTERNAL_CLASSIFIER_PACKET" >&2
    exit 8
  fi
  {
    echo "external_provenance_replay_classifier_packet_used=true"
    echo "provenance_replay_classifier_packet_path=$EXTERNAL_CLASSIFIER_PACKET"
    cat "$EXTERNAL_CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: log=$CLASSIFIER_LOG" >&2
    exit 9
  fi
fi

classifier_packet="${EXTERNAL_CLASSIFIER_PACKET:-$(grep -Eo 'provenance_replay_classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: missing classifier packet $classifier_packet" >&2
  exit 10
fi

required_preflight_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  "current_shell_provenance_replay_admitted=false"
  "renderer_state_write_permission_from_replay=false"
  "renderer_state_write_decision_after_external_provenance_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_preflight_facts[@]}"; do
  if ! grep -F "$fact" "$replay_packet" "$classifier_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: missing preflight fact $fact" >&2
    exit 11
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: protected path modified" >&2
  exit 12
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_packet_version=1"
  echo "provenance_replay_packet=$replay_packet"
  echo "provenance_replay_classifier_packet=$classifier_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  echo "external_provenance_replay_is_not_renderer_state_write_permission=true"
  echo "separate_renderer_state_write_decision_required=true"
  echo "renderer_state_write_after_provenance_replay_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
  echo "current_shell_provenance_replay_admitted=false"
  echo "external_packet_provenance_replay_allowed=false"
  echo "runtime_state_write=false"
  echo "renderer_state_write=false"
  echo "failure_domain=automation_environment"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
} > "$WRITE_DECISION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: route_classification=d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: write_decision_preflight_packet_path=$WRITE_DECISION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: provenance_replay_packet=$replay_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: provenance_replay_classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: separate_renderer_state_write_decision_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: renderer_state_write_after_provenance_replay_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay write decision preflight: human_approved_d3_execution_consumed=false"
