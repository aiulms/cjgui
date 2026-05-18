#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 D3 result-envelope fixture packet，分类当前 shell 与
# future external result envelope 的 admission 状态。
# Truth: result-envelope admission classifier；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-classifier"
FIXTURE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_fixture.sh"
FIXTURE_LOG="$TMP_DIR/d3-result-envelope-fixture.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-result-envelope-classifier.packet"
EXTERNAL_FIXTURE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_FIXTURE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$FIXTURE_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$FIXTURE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing executable fixture script $FIXTURE_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_FIXTURE_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_FIXTURE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: external fixture packet missing $EXTERNAL_FIXTURE_PACKET" >&2
    exit 5
  fi
  {
    echo "external_fixture_packet_used=true"
    echo "fixture_packet_path=$EXTERNAL_FIXTURE_PACKET"
    cat "$EXTERNAL_FIXTURE_PACKET"
  } > "$FIXTURE_LOG"
else
  if ! (
    unset CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED
    env TMPDIR="$TMP_DIR/nested-fixture" zsh "$FIXTURE_SCRIPT"
  ) > "$FIXTURE_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: fixture failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: log=$FIXTURE_LOG" >&2
    exit 6
  fi
fi

required_fixture_facts=(
  "result_envelope_schema_fixture_ready=true"
  "current_shell_result_envelope_accepted=false"
  "current_shell_admission_pending_external_packet=true"
  "future_external_result_envelope_schema_admitted=true"
  "external_metal_capable_shell_packet_required=true"
  "external_approval_consumption_proof_required=true"
  "capability_packet_before_result_envelope_required=true"
  "native_result_packet_schema_required=true"
  "integer_classification_only_required=true"
  "side_effect_classification_required=true"
  "artifact_containment_proof_required=true"
  "no_pointer_or_native_object_payload_required=true"
  "no_production_truth_upgrade_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_fixture_facts[@]}"; do
  if ! grep -F "$fact" "$FIXTURE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing fixture fact $fact" >&2
    exit 7
  fi
done

fixture_packet="${EXTERNAL_FIXTURE_PACKET:-$(grep -Eo 'fixture_packet_path=[^[:space:]]+' "$FIXTURE_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$fixture_packet" || ! -f "$fixture_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing fixture packet $fixture_packet" >&2
  exit 8
fi

current_packet="$(grep -Eo 'current_shell_packet=[^[:space:]]+' "$fixture_packet" | tail -1 | cut -d= -f2-)"
future_packet="$(grep -Eo 'future_external_schema_packet=[^[:space:]]+' "$fixture_packet" | tail -1 | cut -d= -f2-)"
for packet in "$current_packet" "$future_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing nested packet $packet" >&2
    exit 9
  fi
done

required_current_facts=(
  "result_envelope_context=current_shell_environment_blocked"
  "current_shell_result_envelope_accepted=false"
  "current_shell_admission_pending_external_packet=true"
  "failure_domain=automation_environment"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
)
for fact in "${required_current_facts[@]}"; do
  if ! grep -F "$fact" "$current_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing current packet fact $fact" >&2
    exit 10
  fi
done

required_future_facts=(
  "result_envelope_context=future_external_metal_capable_shell"
  "future_external_result_envelope_schema_admitted=true"
  "required_external_metal_capable_shell_packet=true"
  "required_external_approval_consumption_proof=true"
  "required_native_result_packet_schema=true"
  "required_no_pointer_or_native_object_payload=true"
  "required_no_production_truth_upgrade=true"
  "production_singleton_ownership_truth=false"
  "backend_ready_truth=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_future_facts[@]}"; do
  if ! grep -F "$fact" "$future_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: missing future packet fact $fact" >&2
    exit 11
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: protected path modified" >&2
  exit 12
fi

{
  echo "d3_result_envelope_classifier_version=1"
  echo "d3_result_envelope_fixture_reused=true"
  echo "fixture_packet=$fixture_packet"
  echo "current_shell_packet=$current_packet"
  echo "future_external_schema_packet=$future_packet"
  echo "current_shell_result_envelope_admitted=false"
  echo "current_shell_admission_pending_external_packet=true"
  echo "future_external_result_envelope_schema_admitted=true"
  echo "result_envelope_admission_classifier_passed=true"
  echo "external_result_envelope_required=true"
  echo "external_metal_capable_shell_packet_required=true"
  echo "external_approval_consumption_proof_required=true"
  echo "capability_packet_before_result_envelope_required=true"
  echo "native_result_packet_schema_required=true"
  echo "integer_classification_only_required=true"
  echo "side_effect_classification_required=true"
  echo "artifact_containment_proof_required=true"
  echo "no_pointer_or_native_object_payload_required=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: route_classification=d3_result_envelope_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: result_envelope_admission_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: fixture_packet=$fixture_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: current_shell_result_envelope_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: current_shell_admission_pending_external_packet=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: future_external_result_envelope_schema_admitted=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: external_result_envelope_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: no_production_truth_upgrade_required=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope classifier: human_approved_d3_execution_consumed=false"
