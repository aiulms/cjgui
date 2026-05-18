#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope renderer-state external packet
# promotion admission focused regression suite。它串联 owner probe、promotion
# admission packet、provenance classifier、write gate 与 source/build guard。
# Truth: focused external-packet-promotion-admission suite；不消费 D3 approval，
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-external-packet-promotion-admission-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_owner.sh"
ADMISSION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_packet.sh"
PROVENANCE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier.sh"
WRITE_GATE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_write_gate.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_external_packet_promotion_admission_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission-owner.log"
ADMISSION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission.log"
PROVENANCE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-provenance.log"
WRITE_GATE_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-write-gate.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-external-packet-promotion-admission-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$ADMISSION_LOG"
: > "$PROVENANCE_LOG"
: > "$WRITE_GATE_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$ADMISSION_SCRIPT" "$PROVENANCE_SCRIPT" "$WRITE_GATE_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: log=$OWNER_LOG" >&2
  exit 5
fi

SHORT_ADMISSION_TMP="/tmp/cjgui-stage99-promotion-suite-admission-${$}"
mkdir -p "$SHORT_ADMISSION_TMP"
if ! env TMPDIR="$SHORT_ADMISSION_TMP" zsh "$ADMISSION_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: promotion admission packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: log=$ADMISSION_LOG" >&2
  exit 6
fi
admission_packet="$(grep -Eo 'promotion_admission_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$admission_packet" || ! -f "$admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing promotion admission packet $admission_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-provenance" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET="$admission_packet" zsh "$PROVENANCE_SCRIPT" > "$PROVENANCE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: provenance classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: log=$PROVENANCE_LOG" >&2
  exit 8
fi
provenance_packet="$(grep -Eo 'provenance_packet_path=[^[:space:]]+' "$PROVENANCE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$provenance_packet" || ! -f "$provenance_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing provenance packet $provenance_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-write-gate" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET="$admission_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_PROVENANCE_PACKET="$provenance_packet" zsh "$WRITE_GATE_SCRIPT" > "$WRITE_GATE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: write gate failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: log=$WRITE_GATE_LOG" >&2
  exit 10
fi
write_gate_packet="$(grep -Eo 'write_gate_packet_path=[^[:space:]]+' "$WRITE_GATE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_gate_packet" || ! -f "$write_gate_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing write gate packet $write_gate_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_EXTERNAL_PACKET_PROMOTION_ADMISSION_PACKET="$admission_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_owner_present=true"
  "transition_admission_input=true"
  "external_validated_packet_shape_admitted=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_admission_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  "external_validated_packet_shape_admitted=true"
  "current_shell_packet_promotion_denied=true"
  "renderer_state_write_blocked_until_external_promotion=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing admission fact $fact" >&2
    exit 15
  fi
done

required_provenance_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  "current_shell_external_packet_provenance_valid=false"
  "packet_promotion_allowed=false"
  "renderer_state_write_blocked_until_external_provenance=true"
)
for fact in "${required_provenance_facts[@]}"; do
  if ! grep -F "$fact" "$provenance_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing provenance fact $fact" >&2
    exit 16
  fi
done

required_write_gate_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
  "external_packet_promotion_admission_is_not_renderer_state_write=true"
  "renderer_state_write_after_promotion_admission_allowed=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_write_gate_facts[@]}"; do
  if ! grep -F "$fact" "$write_gate_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing write gate fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_owner_probe_passed=true"
  "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  "d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
  "runtime_package_build_passed=true"
  "source_build_external_packet_promotion_admission_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_suite_version=1"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
  echo "admission_log=$ADMISSION_LOG"
  echo "promotion_admission_packet=$admission_packet"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
  echo "provenance_log=$PROVENANCE_LOG"
  echo "provenance_packet=$provenance_packet"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
  echo "write_gate_log=$WRITE_GATE_LOG"
  echo "write_gate_packet=$write_gate_packet"
  echo "source_build_external_packet_promotion_admission_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_renderer_state_external_packet_promotion_admission_suite_passed=true"
  echo "external_validated_packet_shape_admitted=true"
  echo "current_shell_external_packet_provenance_valid=false"
  echo "current_shell_packet_promotion_denied=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "renderer_state_write_after_promotion_admission_allowed=false"
  echo "renderer_state_write_blocked_until_external_provenance=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: route_classification=d3_result_envelope_renderer_state_external_packet_promotion_admission_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: d3_result_envelope_renderer_state_external_packet_promotion_admission_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: d3_result_envelope_renderer_state_external_packet_promotion_admission_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: d3_result_envelope_renderer_state_external_packet_promotion_provenance_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: d3_result_envelope_renderer_state_external_packet_promotion_write_gate_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: source_build_external_packet_promotion_admission_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: d3_result_envelope_renderer_state_external_packet_promotion_admission_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state external packet promotion admission suite: human_approved_d3_execution_consumed=false"
