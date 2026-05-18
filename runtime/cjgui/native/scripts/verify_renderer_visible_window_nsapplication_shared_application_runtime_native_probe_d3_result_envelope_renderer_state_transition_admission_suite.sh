#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state transition admission
# focused regression suite。它串联 owner probe、admission packet、write denial、
# external packet handoff 与 source/build guard。
# Truth: focused transition-admission suite；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-transition-admission-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_owner.sh"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_packet.sh"
WRITE_DENIAL_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_write_denial_classifier.sh"
HANDOFF_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_external_packet_handoff.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_transition_admission_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission-owner.log"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission.log"
WRITE_DENIAL_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-write-denial.log"
HANDOFF_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-handoff.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-transition-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-transition-admission-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$ADMISSION_LOG"
: > "$WRITE_DENIAL_LOG"
: > "$HANDOFF_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$ADMISSION_SCRIPT" "$WRITE_DENIAL_SCRIPT" "$HANDOFF_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: log=$OWNER_LOG" >&2
  exit 5
fi
SHORT_ADMISSION_TMP="/tmp/cjgui-stage98-transition-suite-admission-${$}"
mkdir -p "$SHORT_ADMISSION_TMP"
if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: admission packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: log=$ADMISSION_LOG" >&2
  exit 6
fi
admission_packet="$(grep -Eo 'transition_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing admission packet $admission_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-denial" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" zsh "$WRITE_DENIAL_SCRIPT" > "$WRITE_DENIAL_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: write denial classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: log=$WRITE_DENIAL_LOG" >&2
  exit 8
fi
write_denial_packet="$(grep -Eo 'write_denial_packet_path=[^[:space:]]+' "$WRITE_DENIAL_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_denial_packet" || ! -f "$write_denial_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing write denial packet $write_denial_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-handoff" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_WRITE_DENIAL_PACKET="$write_denial_packet" zsh "$HANDOFF_SCRIPT" > "$HANDOFF_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: external handoff failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: log=$HANDOFF_LOG" >&2
  exit 10
fi
handoff_packet="$(grep -Eo 'external_packet_handoff_packet_path=[^[:space:]]+' "$HANDOFF_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$handoff_packet" || ! -f "$handoff_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing handoff packet $handoff_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_TRANSITION_ADMISSION_PACKET="$admission_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_transition_admission_owner_present=true"
  "renderer_state_planning_input=true"
  "dehydrated_renderer_state_transition_candidate_admitted=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_admission_facts=(
  "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  "dehydrated_renderer_state_transition_candidate_admitted=true"
  "renderer_state_transition_write_admitted=false"
  "external_validated_packet_before_transition_write_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$ADMISSION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing admission fact $fact" >&2
    exit 15
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
  if ! grep -F "$fact" "$WRITE_DENIAL_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing denial fact $fact" >&2
    exit 16
  fi
done

required_handoff_facts=(
  "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  "external_validated_packet_still_required=true"
  "renderer_state_write_blocked_by_admission=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_handoff_facts[@]}"; do
  if ! grep -F "$fact" "$HANDOFF_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing handoff fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_transition_admission_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  "d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
  "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  "runtime_package_build_passed=true"
  "source_build_transition_admission_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_transition_admission_suite_version=1"
  echo "d3_result_envelope_renderer_state_transition_admission_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
  echo "admission_log=$ADMISSION_LOG"
  echo "transition_admission_packet=$admission_packet"
  echo "d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
  echo "write_denial_log=$WRITE_DENIAL_LOG"
  echo "write_denial_packet=$write_denial_packet"
  echo "d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
  echo "handoff_log=$HANDOFF_LOG"
  echo "external_packet_handoff_packet=$handoff_packet"
  echo "source_build_transition_admission_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_transition_admission_suite_passed=true"
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
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: route_classification=d3_result_envelope_renderer_state_transition_admission_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: d3_result_envelope_renderer_state_transition_admission_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: d3_result_envelope_renderer_state_transition_admission_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: d3_result_envelope_renderer_state_transition_write_denial_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: d3_result_envelope_renderer_state_transition_external_packet_handoff_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: source_build_transition_admission_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: d3_result_envelope_renderer_state_transition_admission_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state transition admission suite: human_approved_d3_execution_consumed=false"
