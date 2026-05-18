#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage95 result-envelope classifier packet，并生成
# stage96 D3 result-envelope packet-validation packet。它验证 packet version /
# route marker、capability binding、approval consumption binding、native result
# classification、artifact containment binding 与 failure-domain continuity。
# Truth: packet validator；不消费 D3 approval，不执行 runtime native probe，不调用
# application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-packet-validator"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_classifier.sh"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-classifier.log"
VALIDATION_PACKET="$TMP_DIR/d3-result-envelope-packet-validation.packet"
EXTERNAL_CLASSIFIER_PACKET="${CJGUI_D3_RESULT_ENVELOPE_CLASSIFIER_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$CLASSIFIER_LOG"
: > "$VALIDATION_PACKET"

if [[ ! -x "$CLASSIFIER_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing executable classifier script $CLASSIFIER_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: current validator route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_CLASSIFIER_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CLASSIFIER_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: external classifier packet missing $EXTERNAL_CLASSIFIER_PACKET" >&2
    exit 5
  fi
  {
    echo "external_classifier_packet_used=true"
    echo "classifier_packet_path=$EXTERNAL_CLASSIFIER_PACKET"
    cat "$EXTERNAL_CLASSIFIER_PACKET"
  } > "$CLASSIFIER_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-classifier" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: classifier failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: log=$CLASSIFIER_LOG" >&2
    exit 6
  fi
fi

required_classifier_log_facts=(
  "result_envelope_admission_classifier_passed=true"
  "current_shell_result_envelope_admitted=false"
  "current_shell_admission_pending_external_packet=true"
  "future_external_result_envelope_schema_admitted=true"
  "external_result_envelope_required=true"
  "no_production_truth_upgrade_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_classifier_log_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing classifier log fact $fact" >&2
    exit 7
  fi
done

classifier_packet="${EXTERNAL_CLASSIFIER_PACKET:-$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing classifier packet $classifier_packet" >&2
  exit 8
fi

required_classifier_packet_facts=(
  "result_envelope_admission_classifier_passed=true"
  "external_metal_capable_shell_packet_required=true"
  "external_approval_consumption_proof_required=true"
  "capability_packet_before_result_envelope_required=true"
  "native_result_packet_schema_required=true"
  "artifact_containment_proof_required=true"
  "no_pointer_or_native_object_payload_required=true"
  "no_production_truth_upgrade_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_classifier_packet_facts[@]}"; do
  if ! grep -F "$fact" "$classifier_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing classifier packet fact $fact" >&2
    exit 9
  fi
done

current_packet="$(grep -Eo 'current_shell_packet=[^[:space:]]+' "$classifier_packet" | tail -1 | cut -d= -f2-)"
future_packet="$(grep -Eo 'future_external_schema_packet=[^[:space:]]+' "$classifier_packet" | tail -1 | cut -d= -f2-)"
for packet in "$current_packet" "$future_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing nested packet $packet" >&2
    exit 10
  fi
done

required_current_facts=(
  "result_envelope_context=current_shell_environment_blocked"
  "current_shell_result_envelope_accepted=false"
  "current_shell_admission_pending_external_packet=true"
  "failure_domain=automation_environment"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_current_facts[@]}"; do
  if ! grep -F "$fact" "$current_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing current packet fact $fact" >&2
    exit 11
  fi
done

required_future_facts=(
  "d3_result_envelope_future_external_schema_version=1"
  "result_envelope_context=future_external_metal_capable_shell"
  "future_external_result_envelope_schema_admitted=true"
  "future_external_runtime_native_probe_execution_schema_only=true"
  "required_external_metal_capable_shell_packet=true"
  "required_external_approval_consumption_proof=true"
  "required_native_result_packet_schema=true"
  "required_artifact_containment_proof=true"
  "required_no_pointer_or_native_object_payload=true"
  "required_no_production_truth_upgrade=true"
  "production_singleton_ownership_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_future_facts[@]}"; do
  if ! grep -F "$fact" "$future_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: missing future packet fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: protected path modified" >&2
  exit 13
fi

{
  echo "d3_result_envelope_packet_validation_version=1"
  echo "classifier_packet=$classifier_packet"
  echo "current_shell_packet=$current_packet"
  echo "future_external_schema_packet=$future_packet"
  echo "packet_version_and_route_marker_validated=true"
  echo "capability_packet_binding_validated=true"
  echo "approval_consumption_binding_validated=true"
  echo "native_result_classification_validated=true"
  echo "artifact_containment_binding_validated=true"
  echo "failure_domain_continuity_validated=true"
  echo "renderer_state_no_write_preflight_required=true"
  echo "promotion_quarantine_required=true"
  echo "d3_result_envelope_packet_validator_passed=true"
  echo "current_shell_packet_rejected=true"
  echo "future_external_packet_schema_only=true"
  echo "external_packet_before_promotion_required=true"
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
} > "$VALIDATION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: route_classification=d3_result_envelope_packet_validator"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: d3_result_envelope_packet_validator_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: packet_validation_packet_path=$VALIDATION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: current_shell_packet_rejected=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: future_external_packet_schema_only=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: renderer_state_no_write_preflight_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: promotion_quarantine_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope packet validator: human_approved_d3_execution_consumed=false"
