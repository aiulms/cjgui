#!/usr/bin/env zsh
#
# 维护注释：本脚本是 explicit approval replay checkpoint focused regression suite。
# 它串联 owner probe、checkpoint packet、failure-domain classifier 与 source/build
# checkpoint guard。
# Truth: probe orchestration runner / focused regression suite；不执行 runtime native
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
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-replay-checkpoint-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_owner.sh"
CHECKPOINT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_packet.sh"
FAILURE_DOMAIN_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_failure_domain.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_replay_checkpoint_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/replay-checkpoint-owner.log"
CHECKPOINT_LOG="$TMP_DIR/replay-checkpoint-packet.log"
CLASSIFIER_LOG="$TMP_DIR/replay-checkpoint-failure-domain.log"
SOURCE_BUILD_LOG="$TMP_DIR/replay-checkpoint-source-build-guard.log"
SUITE_PACKET="$TMP_DIR/explicit-approval-replay-checkpoint-suite.packet"
EXTERNAL_REPLAY_AUDIT_SUITE_PACKET="${CJGUI_EXPLICIT_APPROVAL_REPLAY_AUDIT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$CHECKPOINT_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$CHECKPOINT_PACKET_SCRIPT" "$FAILURE_DOMAIN_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-checkpoint" CJGUI_EXPLICIT_APPROVAL_REPLAY_AUDIT_SUITE_PACKET="$EXTERNAL_REPLAY_AUDIT_SUITE_PACKET" zsh "$CHECKPOINT_PACKET_SCRIPT" > "$CHECKPOINT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: checkpoint packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: log=$CHECKPOINT_LOG" >&2
  exit 6
fi

checkpoint_packet="$(grep -Eo 'checkpoint_packet_path=[^[:space:]]+' "$CHECKPOINT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$checkpoint_packet" || ! -f "$checkpoint_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing checkpoint packet $checkpoint_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_EXPLICIT_APPROVAL_REPLAY_CHECKPOINT_PACKET="$checkpoint_packet" zsh "$FAILURE_DOMAIN_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: failure-domain classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: log=$CLASSIFIER_LOG" >&2
  exit 8
fi
if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_EXPLICIT_APPROVAL_REPLAY_CHECKPOINT_PACKET="$checkpoint_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: log=$SOURCE_BUILD_LOG" >&2
  exit 9
fi

required_owner_facts=(
  "explicit_approval_replay_checkpoint_owner_present=true"
  "explicit_approval_replay_audit_input=true"
  "replay_audit_suite_packet_required=true"
  "checkpoint_packet_reuse_contract_required=true"
  "failure_domain_classifier_required=true"
  "source_build_checkpoint_guard_required=true"
  "focused_checkpoint_suite_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing owner fact $fact" >&2
    exit 10
  fi
done

required_checkpoint_facts=(
  "replay_checkpoint_packet_ready=true"
  "bounded_replay_audit_suite_passed=true"
  "checkpoint_packet_reuse_contract_passed=true"
  "nested_checkpoint_packets_reachable=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_checkpoint_facts[@]}"; do
  if ! grep -F "$fact" "$CHECKPOINT_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing checkpoint fact $fact" >&2
    exit 11
  fi
done

required_classifier_facts=(
  "replay_checkpoint_failure_domain_classifier_passed=true"
  "failure_domain=none"
  "code_failure_domain=false"
  "environment_blocker_detected=false"
  "automation_orchestration_blocker_detected=false"
  "non_d3_checkpoint_route_continues=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing classifier fact $fact" >&2
    exit 12
  fi
done

required_source_facts=(
  "replay_checkpoint_owner_probe_passed=true"
  "replay_checkpoint_packet_ready=true"
  "replay_checkpoint_failure_domain_classifier_passed=true"
  "runtime_package_build_passed=true"
  "source_build_checkpoint_guard_passed=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing source/build fact $fact" >&2
    exit 13
  fi
done

classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
source_build_checkpoint_packet="$(grep -Eo 'source_build_checkpoint_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$checkpoint_packet" "$classifier_packet" "$source_build_checkpoint_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: missing packet $packet" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: protected path modified" >&2
  exit 15
fi

{
  echo "explicit_approval_replay_checkpoint_suite_version=1"
  echo "replay_checkpoint_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "replay_checkpoint_packet_ready=true"
  echo "checkpoint_log=$CHECKPOINT_LOG"
  echo "checkpoint_packet=$checkpoint_packet"
  echo "replay_checkpoint_failure_domain_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_checkpoint_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_checkpoint_packet=$source_build_checkpoint_packet"
  echo "explicit_approval_replay_checkpoint_suite_passed=true"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "d3_runtime_native_probe_approval_required=true"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
  echo "failure_domain=none"
  echo "code_failure_domain=false"
  echo "environment_blocker_detected=false"
  echo "automation_orchestration_blocker_detected=false"
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

echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: route_classification=runtime_native_probe_explicit_approval_replay_checkpoint_suite"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: replay_checkpoint_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: replay_checkpoint_packet_ready=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: replay_checkpoint_failure_domain_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: source_build_checkpoint_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: explicit_approval_replay_checkpoint_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: replay_checkpoint_suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: checkpoint_packet=$checkpoint_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: source_build_checkpoint_packet=$source_build_checkpoint_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: failure_domain=none"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: environment_blocker_detected=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: automation_orchestration_blocker_detected=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval replay checkpoint suite: next_route=human_approved_d3_runtime_native_probe_execution_or_non_d3_checkpoint_suite_rerun"
