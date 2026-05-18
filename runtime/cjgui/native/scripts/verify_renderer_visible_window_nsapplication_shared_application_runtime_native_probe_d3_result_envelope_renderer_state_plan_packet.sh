#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage96 packet-validation packet 和 promotion classifier
# packet，并生成 stage97 renderer-state planning packet。它只描述 transition
# plan，不写 renderer state。
# Truth: renderer-state plan packet；不消费 D3 approval，不执行 runtime native
# probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-plan-packet"
VALIDATOR_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validator.sh"
PROMOTION_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_promotion_classifier.sh"
VALIDATOR_LOG="$TMP_DIR/d3-result-envelope-packet-validator.log"
PROMOTION_LOG="$TMP_DIR/d3-result-envelope-promotion-classifier.log"
PLAN_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-plan.packet"
EXTERNAL_VALIDATION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET:-}"
EXTERNAL_PROMOTION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_PROMOTION_PACKET:-}"
RUNTIME_STATE_FILE="$ROOT_DIR/src/runtime_state.cj"

mkdir -p "$TMP_DIR"
: > "$VALIDATOR_LOG"
: > "$PROMOTION_LOG"
: > "$PLAN_PACKET"

for script in "$VALIDATOR_SCRIPT" "$PROMOTION_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: current plan route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_VALIDATION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_VALIDATION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: external validation packet missing $EXTERNAL_VALIDATION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_validation_packet_used=true"
    echo "packet_validation_packet_path=$EXTERNAL_VALIDATION_PACKET"
    cat "$EXTERNAL_VALIDATION_PACKET"
  } > "$VALIDATOR_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-validator" zsh "$VALIDATOR_SCRIPT" > "$VALIDATOR_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: validator failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: log=$VALIDATOR_LOG" >&2
    exit 6
  fi
fi

validation_packet="${EXTERNAL_VALIDATION_PACKET:-$(grep -Eo 'packet_validation_packet_path=[^[:space:]]+' "$VALIDATOR_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$validation_packet" || ! -f "$validation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: missing validation packet $validation_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_PROMOTION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PROMOTION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: external promotion packet missing $EXTERNAL_PROMOTION_PACKET" >&2
    exit 8
  fi
  {
    echo "external_promotion_packet_used=true"
    echo "promotion_packet_path=$EXTERNAL_PROMOTION_PACKET"
    cat "$EXTERNAL_PROMOTION_PACKET"
  } > "$PROMOTION_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-promotion" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" zsh "$PROMOTION_SCRIPT" > "$PROMOTION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: promotion classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: log=$PROMOTION_LOG" >&2
    exit 9
  fi
fi

promotion_packet="${EXTERNAL_PROMOTION_PACKET:-$(grep -Eo 'promotion_packet_path=[^[:space:]]+' "$PROMOTION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$promotion_packet" || ! -f "$promotion_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: missing promotion packet $promotion_packet" >&2
  exit 10
fi

required_validation_facts=(
  "d3_result_envelope_packet_validator_passed=true"
  "packet_version_and_route_marker_validated=true"
  "capability_packet_binding_validated=true"
  "approval_consumption_binding_validated=true"
  "native_result_classification_validated=true"
  "artifact_containment_binding_validated=true"
  "failure_domain_continuity_validated=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "renderer_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_validation_facts[@]}"; do
  if ! grep -F "$fact" "$validation_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: missing validation fact $fact" >&2
    exit 11
  fi
done

required_promotion_facts=(
  "packet_promotion_classifier_passed=true"
  "packet_promotion_allowed=false"
  "packet_promotion_quarantined=true"
  "renderer_state_no_write_preflight_passed=true"
  "renderer_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_promotion_facts[@]}"; do
  if ! grep -F "$fact" "$promotion_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: missing promotion fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: protected path modified" >&2
  exit 13
fi

runtime_state_line_count="$(wc -l < "$RUNTIME_STATE_FILE" | tr -d '[:space:]')"
if [[ "$runtime_state_line_count" != "10065" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: unexpected runtime_state.cj line count $runtime_state_line_count" >&2
  exit 14
fi

{
  echo "d3_result_envelope_renderer_state_plan_packet_version=1"
  echo "packet_validation_packet=$validation_packet"
  echo "promotion_packet=$promotion_packet"
  echo "validated_packet_before_renderer_state_plan=true"
  echo "quarantined_packet_as_planning_input=true"
  echo "renderer_state_transition_descriptor_prepared=true"
  echo "renderer_state_transition_descriptor_mode=dehydrated_no_write"
  echo "no_write_gate_before_promotion_confirmed=true"
  echo "promotion_hold_until_external_validation_confirmed=true"
  echo "state_plan_artifact_containment_confirmed=true"
  echo "failure_domain_continuity_confirmed=true"
  echo "runtime_state_line_count=$runtime_state_line_count"
  echo "runtime_state_line_count_invariant=true"
  echo "d3_result_envelope_renderer_state_plan_packet_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "current_shell_promotion_rejected=true"
  echo "renderer_state_planning_dehydrated=true"
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
} > "$PLAN_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: route_classification=d3_result_envelope_renderer_state_plan_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: d3_result_envelope_renderer_state_plan_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: renderer_state_plan_packet_path=$PLAN_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: packet_validation_packet=$validation_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: promotion_packet=$promotion_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: renderer_state_transition_descriptor_prepared=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: no_write_gate_before_promotion_confirmed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: promotion_hold_until_external_validation_confirmed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: runtime_state_line_count_invariant=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state plan packet: human_approved_d3_execution_consumed=false"
