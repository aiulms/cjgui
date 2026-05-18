#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state external packet
# provenance replay focused regression suite。它串联 owner probe、replay packet、
# classifier、write-decision preflight 与 source/build guard。
# Truth: focused external-packet-provenance-replay suite；不消费 D3 approval，
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-provenance-replay-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_owner.sh"
REPLAY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier.sh"
WRITE_DECISION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_provenance_replay_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-owner.log"
REPLAY_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-classifier.log"
WRITE_DECISION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-write-decision.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-provenance-replay-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$REPLAY_LOG"
: > "$CLASSIFIER_LOG"
: > "$WRITE_DECISION_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$REPLAY_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$WRITE_DECISION_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: log=$OWNER_LOG" >&2
  exit 5
fi

SHORT_REPLAY_TMP="/tmp/cjgui-stage100-provenance-suite-replay-${$}"
mkdir -p "$SHORT_REPLAY_TMP"
if ! env TMPDIR="$SHORT_REPLAY_TMP" zsh "$REPLAY_PACKET_SCRIPT" > "$REPLAY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: provenance replay packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: log=$REPLAY_LOG" >&2
  exit 6
fi
replay_packet="$(grep -Eo 'provenance_replay_packet_path=[^[:space:]]+' "$REPLAY_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$replay_packet" || ! -f "$replay_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing provenance replay packet $replay_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: log=$CLASSIFIER_LOG" >&2
  exit 8
fi
classifier_packet="$(grep -Eo 'provenance_replay_classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing classifier packet $classifier_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-write-decision" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_CLASSIFIER_PACKET="$classifier_packet" zsh "$WRITE_DECISION_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: write decision preflight failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: log=$WRITE_DECISION_LOG" >&2
  exit 10
fi
write_decision_packet="$(grep -Eo 'write_decision_preflight_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_decision_packet" || ! -f "$write_decision_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing write decision packet $write_decision_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROVENANCE_REPLAY_PACKET="$replay_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_present=true"
  "promotion_admission_input=true"
  "external_packet_provenance_replay_route_opened=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_replay_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "external_packet_provenance_replay_ready=true"
  "current_shell_provenance_replay_denied=true"
  "renderer_state_write_decision_after_external_provenance_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_replay_facts[@]}"; do
  if ! grep -F "$fact" "$replay_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing replay fact $fact" >&2
    exit 15
  fi
done

required_classifier_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  "shape_admission_is_not_provenance_truth=true"
  "current_shell_provenance_replay_admitted=false"
  "renderer_state_write_permission_from_replay=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$classifier_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing classifier fact $fact" >&2
    exit 16
  fi
done

required_write_decision_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  "separate_renderer_state_write_decision_required=true"
  "renderer_state_write_after_provenance_replay_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_write_decision_facts[@]}"; do
  if ! grep -F "$fact" "$write_decision_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing write decision fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  "runtime_package_build_passed=true"
  "source_build_external_packet_provenance_replay_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_version=1"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
  echo "replay_log=$REPLAY_LOG"
  echo "provenance_replay_packet=$replay_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "provenance_replay_classifier_packet=$classifier_packet"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
  echo "write_decision_log=$WRITE_DECISION_LOG"
  echo "write_decision_preflight_packet=$write_decision_packet"
  echo "source_build_external_packet_provenance_replay_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_passed=true"
  echo "external_packet_provenance_replay_ready=true"
  echo "current_shell_provenance_replay_denied=true"
  echo "current_shell_provenance_replay_admitted=false"
  echo "external_packet_provenance_replay_allowed=false"
  echo "shape_admission_is_not_provenance_truth=true"
  echo "separate_renderer_state_write_decision_required=true"
  echo "renderer_state_write_after_provenance_replay_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance_and_write_decision=true"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: route_classification=d3_result_envelope_renderer_state_external_packet_provenance_replay_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: d3_result_envelope_renderer_state_external_packet_provenance_replay_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: d3_result_envelope_renderer_state_external_packet_provenance_replay_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: d3_result_envelope_renderer_state_external_packet_provenance_replay_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: d3_result_envelope_renderer_state_external_packet_provenance_replay_write_decision_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: source_build_external_packet_provenance_replay_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance_replay_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: d3_result_envelope_renderer_state_external_packet_provenance_replay_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet provenance replay suite: human_approved_d3_execution_consumed=false"
