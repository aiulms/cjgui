#!/usr/bin/env zsh
#
# 维护注释：本脚本基于 replay checkpoint packet 做 failure-domain classification。
# 它区分 non-D3 replay checkpoint 可继续、D3 approval 仍需人工、以及 code failure
# 是否出现。
# Truth: environment / failure-domain classification follow-up；不执行 runtime native
# probe，不消费 D3 approval，不调用 application accessor，不创建 singleton，不扩
# native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-replay-checkpoint-failure-domain"
CHECKPOINT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_packet.sh"
CHECKPOINT_LOG="$TMP_DIR/replay-checkpoint-packet.log"
CLASSIFIER_PACKET="$TMP_DIR/explicit-approval-replay-checkpoint-failure-domain.packet"
EXTERNAL_CHECKPOINT_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_CHECKPOINT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$CHECKPOINT_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$CHECKPOINT_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: missing executable checkpoint packet script $CHECKPOINT_PACKET_SCRIPT" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

external_checkpoint_packet_used=false
if [[ -n "$EXTERNAL_CHECKPOINT_PACKET" ]]; then
  if [[ ! -f "$EXTERNAL_CHECKPOINT_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: external checkpoint packet missing $EXTERNAL_CHECKPOINT_PACKET" >&2
    exit 5
  fi
  external_checkpoint_packet_used=true
  {
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: external_checkpoint_packet_used=true"
    echo "route_classification=runtime_native_probe_explicit_approval_replay_checkpoint_packet"
    echo "checkpoint_packet_path=$EXTERNAL_CHECKPOINT_PACKET"
    cat "$EXTERNAL_CHECKPOINT_PACKET"
  } > "$CHECKPOINT_LOG"
else
  if ! env TMPDIR="$TMP_DIR/nested-checkpoint" zsh "$CHECKPOINT_PACKET_SCRIPT" > "$CHECKPOINT_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: checkpoint packet script failed" >&2
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: log=$CHECKPOINT_LOG" >&2
    exit 6
  fi
fi

required_checkpoint_facts=(
  "route_classification=runtime_native_probe_explicit_approval_replay_checkpoint_packet"
  "replay_checkpoint_packet_ready=true"
  "bounded_replay_audit_suite_passed=true"
  "checkpoint_packet_reuse_contract_passed=true"
  "nested_checkpoint_packets_reachable=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)
for fact in "${required_checkpoint_facts[@]}"; do
  if ! grep -F "$fact" "$CHECKPOINT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: missing checkpoint fact $fact" >&2
    exit 7
  fi
done

checkpoint_packet="${EXTERNAL_CHECKPOINT_PACKET:-$(grep -Eo 'checkpoint_packet_path=[^[:space:]]+' "$CHECKPOINT_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$checkpoint_packet" || ! -f "$checkpoint_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: missing checkpoint packet $checkpoint_packet" >&2
  exit 8
fi

for fact in \
  "replay_checkpoint_packet_ready=true" \
  "bounded_replay_audit_suite_passed=true" \
  "checkpoint_packet_reuse_contract_passed=true" \
  "code_failure_domain=false" \
  "runtime_native_probe_execution=false" \
  "human_approved_d3_execution_consumed=false" \
  "application_singleton_accessor_call=false" \
  "native_bridge_expansion=false" \
  "protected_path_modified=false" \
  "production_public_c_abi_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "cjpm_toml_change=false"; do
  if ! grep -F "$fact" "$checkpoint_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: missing checkpoint packet fact $fact" >&2
    exit 9
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: protected path modified" >&2
  exit 10
fi

{
  echo "explicit_approval_replay_checkpoint_failure_domain_version=1"
  echo "replay_checkpoint_failure_domain_classifier_passed=true"
  echo "external_checkpoint_packet_used=$external_checkpoint_packet_used"
  echo "checkpoint_log=$CHECKPOINT_LOG"
  echo "checkpoint_packet=$checkpoint_packet"
  echo "failure_domain=none"
  echo "code_failure_domain=false"
  echo "environment_blocker_detected=false"
  echo "automation_orchestration_blocker_detected=false"
  echo "d3_execution_boundary_classification=external_human_approval_required"
  echo "non_d3_checkpoint_route_continues=true"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
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

echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: route_classification=runtime_native_probe_explicit_approval_replay_checkpoint_failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: replay_checkpoint_failure_domain_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: checkpoint_packet=$checkpoint_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: external_checkpoint_packet_used=$external_checkpoint_packet_used"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: failure_domain=none"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: environment_blocker_detected=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: automation_orchestration_blocker_detected=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: d3_execution_boundary_classification=external_human_approval_required"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: non_d3_checkpoint_route_continues=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint failure domain: renderer_state_write=false"
