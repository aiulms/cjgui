#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 D3 result-envelope packet-validation 与 renderer-state
# no-write preflight packet，分类 result-envelope 是否可进入后续 promotion。
# 当前自动化 shell 只能得到 quarantined / not-promoted 结论。
# Truth: result-envelope promotion classifier；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-promotion-classifier"
VALIDATOR_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validator.sh"
PREFLIGHT_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_preflight.sh"
VALIDATOR_LOG="$TMP_DIR/d3-result-envelope-packet-validator.log"
PREFLIGHT_LOG="$TMP_DIR/d3-result-envelope-renderer-state-preflight.log"
PROMOTION_PACKET="$TMP_DIR/d3-result-envelope-promotion-classifier.packet"
EXTERNAL_VALIDATION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET:-}"
EXTERNAL_PREFLIGHT_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_PREFLIGHT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$VALIDATOR_LOG"
: > "$PREFLIGHT_LOG"
: > "$PROMOTION_PACKET"

for script in "$VALIDATOR_SCRIPT" "$PREFLIGHT_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: current classifier route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_VALIDATION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_VALIDATION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: external validation packet missing $EXTERNAL_VALIDATION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_validation_packet_used=true"
    echo "packet_validation_packet_path=$EXTERNAL_VALIDATION_PACKET"
    cat "$EXTERNAL_VALIDATION_PACKET"
  } > "$VALIDATOR_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-validator" zsh "$VALIDATOR_SCRIPT" > "$VALIDATOR_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: validator failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: log=$VALIDATOR_LOG" >&2
    exit 6
  fi
fi

validation_packet="${EXTERNAL_VALIDATION_PACKET:-$(grep -Eo 'packet_validation_packet_path=[^[:space:]]+' "$VALIDATOR_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$validation_packet" || ! -f "$validation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: missing validation packet $validation_packet" >&2
  exit 7
fi

if [[ -n "$EXTERNAL_PREFLIGHT_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_PREFLIGHT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: external preflight packet missing $EXTERNAL_PREFLIGHT_PACKET" >&2
    exit 8
  fi
  {
    echo "external_preflight_packet_used=true"
    echo "preflight_packet_path=$EXTERNAL_PREFLIGHT_PACKET"
    cat "$EXTERNAL_PREFLIGHT_PACKET"
  } > "$PREFLIGHT_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-preflight" CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET="$validation_packet" zsh "$PREFLIGHT_SCRIPT" > "$PREFLIGHT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: preflight failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: log=$PREFLIGHT_LOG" >&2
    exit 9
  fi
fi

preflight_packet="${EXTERNAL_PREFLIGHT_PACKET:-$(grep -Eo 'preflight_packet_path=[^[:space:]]+' "$PREFLIGHT_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$preflight_packet" || ! -f "$preflight_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: missing preflight packet $preflight_packet" >&2
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
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "external_packet_before_promotion_required=true"
  "renderer_state_write=false"
)
for fact in "${required_validation_facts[@]}"; do
  if ! grep -F "$fact" "$validation_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: missing validation fact $fact" >&2
    exit 11
  fi
done

required_preflight_facts=(
  "renderer_state_no_write_preflight_passed=true"
  "renderer_state_write_blocked_before_promotion=true"
  "packet_promotion_requires_preflight=true"
  "packet_promotion_quarantined=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "renderer_state_write=false"
)
for fact in "${required_preflight_facts[@]}"; do
  if ! grep -F "$fact" "$preflight_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: missing preflight fact $fact" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: protected path modified" >&2
  exit 13
fi

{
  echo "d3_result_envelope_promotion_classifier_version=1"
  echo "packet_validation_packet=$validation_packet"
  echo "renderer_state_preflight_packet=$preflight_packet"
  echo "d3_result_envelope_packet_validator_passed=true"
  echo "renderer_state_no_write_preflight_passed=true"
  echo "packet_promotion_classifier_passed=true"
  echo "packet_promotion_allowed=false"
  echo "packet_promotion_quarantined=true"
  echo "external_packet_before_promotion_required=true"
  echo "renderer_state_no_write_preflight_required=true"
  echo "current_shell_packet_rejected=true"
  echo "future_external_packet_schema_only=true"
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
} > "$PROMOTION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: route_classification=d3_result_envelope_promotion_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: packet_promotion_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: promotion_packet_path=$PROMOTION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: packet_validation_packet=$validation_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: renderer_state_preflight_packet=$preflight_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: packet_promotion_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: packet_promotion_quarantined=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope promotion classifier: human_approved_d3_execution_consumed=false"
