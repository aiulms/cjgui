#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 external packet provenance replay packet，并验证 replay
# contract 不能被解释成 current-shell provenance truth 或 renderer-state write
# permission。
# Truth: external packet provenance replay classifier；不消费 D3 approval，不执行
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-provenance-replay-classifier"
REPLAY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh"
REPLAY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-classifier.packet"
EXTERNAL_REPLAY_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$REPLAY_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$REPLAY_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: missing executable script $REPLAY_PACKET_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_REPLAY_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_REPLAY_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: external replay packet missing $EXTERNAL_REPLAY_PACKET" >&2
    exit 5
  fi
  {
    echo "external_provenance_replay_packet_used=true"
    echo "provenance_replay_packet_path=$EXTERNAL_REPLAY_PACKET"
    cat "$EXTERNAL_REPLAY_PACKET"
  } > "$REPLAY_LOG"
else
  SHORT_REPLAY_TMP="/tmp/cjgui-stage100-provenance-classifier-replay-${$}"
  mkdir -p "$SHORT_REPLAY_TMP"
  if ! env TMPDIR="$SHORT_REPLAY_TMP" zsh "$REPLAY_PACKET_SCRIPT" > "$REPLAY_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: provenance replay packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: log=$REPLAY_LOG" >&2
    exit 6
  fi
fi

replay_packet="${EXTERNAL_REPLAY_PACKET:-$(grep -Eo 'provenance_replay_packet_path=[^[:space:]]+' "$REPLAY_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$replay_packet" || ! -f "$replay_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: missing provenance replay packet $replay_packet" >&2
  exit 7
fi

required_replay_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "external_packet_provenance_replay_ready=true"
  "external_validated_packet_production_required_before_replay=true"
  "external_metal_capable_provenance_replay_required=true"
  "shape_admission_separated_from_provenance_replay=true"
  "current_shell_provenance_replay_denied=true"
  "current_shell_provenance_replay_admitted=false"
  "renderer_state_write_decision_after_external_provenance_required=true"
  "provenance_replay_does_not_write_renderer_state=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_replay_facts[@]}"; do
  if ! grep -F "$fact" "$replay_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: missing replay fact $fact" >&2
    exit 8
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: protected path modified" >&2
  exit 9
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_packet_version=1"
  echo "provenance_replay_packet=$replay_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  echo "provenance_replay_packet_shape_admitted=true"
  echo "provenance_replay_contract_admitted=true"
  echo "shape_admission_is_not_provenance_truth=true"
  echo "current_shell_provenance_replay_admitted=false"
  echo "current_shell_external_packet_provenance_valid=false"
  echo "external_packet_provenance_replay_allowed=false"
  echo "external_validated_packet_production_pending=true"
  echo "renderer_state_write_permission_from_replay=false"
  echo "renderer_state_write_decision_after_external_provenance_required=true"
  echo "no_production_truth_upgrade_required=true"
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
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: route_classification=d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: provenance_replay_classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: provenance_replay_packet=$replay_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: current_shell_provenance_replay_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: renderer_state_write_permission_from_replay=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay classifier: human_approved_d3_execution_consumed=false"
