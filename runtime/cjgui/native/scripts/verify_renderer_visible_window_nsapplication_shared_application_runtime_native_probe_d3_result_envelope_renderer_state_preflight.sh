#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 D3 result-envelope packet-validation packet，并执行
# renderer-state no-write preflight。它只验证 packet promotion 之前的 no-write
# 边界，不写 renderer state。
# Truth: renderer-state no-write preflight；不消费 D3 approval，不执行 runtime
# native probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-renderer-state-preflight"
VALIDATOR_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_packet_validator.sh"
VALIDATOR_LOG="$TMP_DIR/d3-result-envelope-packet-validator.log"
PREFLIGHT_PACKET="$TMP_DIR/d3-result-envelope-renderer-state-preflight.packet"
EXTERNAL_VALIDATION_PACKET="${CJGUI_D3_RESULT_ENVELOPE_PACKET_VALIDATION_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$VALIDATOR_LOG"
: > "$PREFLIGHT_PACKET"

if [[ ! -x "$VALIDATOR_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: missing executable validator script $VALIDATOR_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: current preflight route must not consume D3 approval" >&2
  exit 4
fi

if [[ -n "$EXTERNAL_VALIDATION_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_VALIDATION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: external validation packet missing $EXTERNAL_VALIDATION_PACKET" >&2
    exit 5
  fi
  {
    echo "external_validation_packet_used=true"
    echo "packet_validation_packet_path=$EXTERNAL_VALIDATION_PACKET"
    cat "$EXTERNAL_VALIDATION_PACKET"
  } > "$VALIDATOR_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-validator" zsh "$VALIDATOR_SCRIPT" > "$VALIDATOR_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: validator failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: log=$VALIDATOR_LOG" >&2
    exit 6
  fi
fi

required_validator_log_facts=(
  "d3_result_envelope_packet_validator_passed=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_validator_log_facts[@]}"; do
  if ! grep -F "$fact" "$VALIDATOR_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: missing validator log fact $fact" >&2
    exit 7
  fi
done

validation_packet="${EXTERNAL_VALIDATION_PACKET:-$(grep -Eo 'packet_validation_packet_path=[^[:space:]]+' "$VALIDATOR_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$validation_packet" || ! -f "$validation_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: missing validation packet $validation_packet" >&2
  exit 8
fi

required_validator_packet_facts=(
  "d3_result_envelope_packet_validator_passed=true"
  "packet_version_and_route_marker_validated=true"
  "capability_packet_binding_validated=true"
  "approval_consumption_binding_validated=true"
  "native_result_classification_validated=true"
  "artifact_containment_binding_validated=true"
  "failure_domain_continuity_validated=true"
  "renderer_state_no_write_preflight_required=true"
  "promotion_quarantine_required=true"
  "current_shell_packet_rejected=true"
  "future_external_packet_schema_only=true"
  "renderer_state_write=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_validator_packet_facts[@]}"; do
  if ! grep -F "$fact" "$validation_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: missing validation packet fact $fact" >&2
    exit 9
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: protected path modified" >&2
  exit 10
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' '*.sh' \
  | grep -E '^\+' \
  | grep -E 'renderer_state_write[=]true|runtime_state_write[=]true|backend_ready_truth[=]true|production_singleton_ownership_truth[=]true' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: forbidden truth/write diff found" >&2
  exit 11
fi

{
  echo "d3_result_envelope_renderer_state_preflight_version=1"
  echo "packet_validation_packet=$validation_packet"
  echo "renderer_state_no_write_preflight_passed=true"
  echo "renderer_state_write_blocked_before_promotion=true"
  echo "packet_promotion_requires_preflight=true"
  echo "packet_promotion_quarantined=true"
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
} > "$PREFLIGHT_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: route_classification=d3_result_envelope_renderer_state_preflight"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: renderer_state_no_write_preflight_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: preflight_packet_path=$PREFLIGHT_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: packet_validation_packet=$validation_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: renderer_state_write_blocked_before_promotion=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: packet_promotion_quarantined=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope renderer state preflight: human_approved_d3_execution_consumed=false"
