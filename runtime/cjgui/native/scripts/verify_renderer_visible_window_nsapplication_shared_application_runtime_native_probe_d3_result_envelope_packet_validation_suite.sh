#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope packet-validation focused regression
# suite。它串联 owner probe、packet validator、renderer-state no-write
# preflight、promotion classifier 与 source/build guard。
# Truth: focused packet-validation suite；不消费 D3 approval，不执行 runtime native
# probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-packet-validation-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validation_owner.sh"
VALIDATOR_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validator.sh"
PREFLIGHT_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_preflight.sh"
PROMOTION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_promotion_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validation_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-packet-validation-owner.log"
VALIDATOR_LOG="$TMP_DIR/d3-result-envelope-packet-validator.log"
PREFLIGHT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-preflight.log"
PROMOTION_LOG="$TMP_DIR/d3-result-envelope-promotion-classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-packet-validation-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-packet-validation-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$VALIDATOR_LOG"
: > "$PREFLIGHT_LOG"
: > "$PROMOTION_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$VALIDATOR_SCRIPT" "$PREFLIGHT_SCRIPT" "$PROMOTION_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-validator" zsh "$VALIDATOR_SCRIPT" > "$VALIDATOR_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: packet validator failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: log=$VALIDATOR_LOG" >&2
  exit 6
fi

validation_packet="$(grep -Eo 'packet_validation_packet_path=[^[:space:]]+' "$VALIDATOR_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$validation_packet" || ! -f "$validation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing validation packet $validation_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-preflight" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" zsh "$PREFLIGHT_SCRIPT" > "$PREFLIGHT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: renderer-state preflight failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: log=$PREFLIGHT_LOG" >&2
  exit 8
fi
preflight_packet="$(grep -Eo 'preflight_packet_path=[^[:space:]]+' "$PREFLIGHT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$preflight_packet" || ! -f "$preflight_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing preflight packet $preflight_packet" >&2
  exit 9
fi

if ! env TMPDIR="$TMP_DIR/nested-promotion" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PREFLIGHT_PACKET="$preflight_packet" zsh "$PROMOTION_SCRIPT" > "$PROMOTION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: promotion classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: log=$PROMOTION_LOG" >&2
  exit 10
fi
promotion_packet="$(grep -Eo 'promotion_packet_path=[^[:space:]]+' "$PROMOTION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$promotion_packet" || ! -f "$promotion_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing promotion packet $promotion_packet" >&2
  exit 11
fi

if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: log=$SOURCE_BUILD_LOG" >&2
  exit 12
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing source/build packet $source_build_packet" >&2
  exit 13
fi

required_owner_facts=(
  "d3_result_envelope_packet_validation_owner_present=true"
  "external_packet_before_promotion_required=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing owner fact $fact" >&2
    exit 14
  fi
done

required_validator_facts=(
  "d3_result_envelope_packet_validator_passed=true"
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_validator_facts[@]}"; do
  if ! grep -F "$fact" "$VALIDATOR_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing validator fact $fact" >&2
    exit 15
  fi
done

required_preflight_facts=(
  "renderer_state_no_write_preflight_passed=true"
  "renderer_state_write_blocked_before_promotion=true"
  "packet_promotion_quarantined=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_preflight_facts[@]}"; do
  if ! grep -F "$fact" "$PREFLIGHT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing preflight fact $fact" >&2
    exit 16
  fi
done

required_promotion_facts=(
  "packet_promotion_classifier_passed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_promotion_facts[@]}"; do
  if ! grep -F "$fact" "$PROMOTION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing promotion fact $fact" >&2
    exit 17
  fi
done

required_source_facts=(
  "d3_result_envelope_packet_validation_owner_probe_passed=true"
  "d3_result_envelope_packet_validator_passed=true"
  "renderer_state_no_write_preflight_passed=true"
  "packet_promotion_classifier_passed=true"
  "runtime_package_build_passed=true"
  "source_build_packet_validation_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: missing source/build fact $fact" >&2
    exit 18
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: protected path modified" >&2
  exit 19
fi

{
  echo "d3_result_envelope_packet_validation_suite_version=1"
  echo "d3_result_envelope_packet_validation_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_packet_validator_passed=true"
  echo "validator_log=$VALIDATOR_LOG"
  echo "packet_validation_packet=$validation_packet"
  echo "renderer_state_no_write_preflight_passed=true"
  echo "preflight_log=$PREFLIGHT_LOG"
  echo "renderer_state_preflight_packet=$preflight_packet"
  echo "packet_promotion_classifier_passed=true"
  echo "promotion_log=$PROMOTION_LOG"
  echo "promotion_packet=$promotion_packet"
  echo "source_build_packet_validation_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_packet_validation_suite_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "current_shell_packet_rejected=true"
  echo "future_external_packet_schema_only=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: route_classification=d3_result_envelope_packet_validation_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: d3_result_envelope_packet_validation_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: d3_result_envelope_packet_validator_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: renderer_state_no_write_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: packet_promotion_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: source_build_packet_validation_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: d3_result_envelope_packet_validation_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: packet_validation_packet=$validation_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: renderer_state_preflight_packet=$preflight_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: promotion_packet=$promotion_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: source_build_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: packet_promotion_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: packet_promotion_quarantined=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validation suite: next_route=renderer_state_planning_or_external_packet_promotion_after_metal_capable_shell"
