#!/usr/bin/env zsh
#
# 维护注释：本脚本是 explicit approval handoff evidence mesh runner。它串联
# owner probe、handoff packet consistency、native bridge replay 与 failure-domain
# continuity，生成不消费 D3 approval 的 mesh packet。
# Truth: probe orchestration runner / focused regression suite；不执行 runtime
# native probe，不消费 D3 approval，不调用 application accessor，不创建 singleton，
# 不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-explicit-approval-mesh-runner"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_evidence_mesh_owner.sh"
PACKET_CONSISTENCY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_handoff_packet_consistency.sh"
NATIVE_REPLAY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_native_bridge_replay_guard.sh"
FAILURE_CONTINUITY="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_failure_domain_continuity.sh"
OWNER_LOG="$TMP_DIR/evidence-mesh-owner.log"
CONSISTENCY_LOG="$TMP_DIR/handoff-packet-consistency.log"
NATIVE_REPLAY_LOG="$TMP_DIR/native-bridge-replay.log"
FAILURE_CONTINUITY_LOG="$TMP_DIR/failure-domain-continuity.log"
MESH_PACKET="$TMP_DIR/explicit-approval-verification-mesh.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$OWNER_LOG"
: > "$CONSISTENCY_LOG"
: > "$NATIVE_REPLAY_LOG"
: > "$FAILURE_CONTINUITY_LOG"
: > "$MESH_PACKET"

for script in "$OWNER_PROBE" "$PACKET_CONSISTENCY" "$NATIVE_REPLAY" "$FAILURE_CONTINUITY"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-consistency" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$PACKET_CONSISTENCY" > "$CONSISTENCY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: packet consistency failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: log=$CONSISTENCY_LOG" >&2
  exit 6
fi
if ! env TMPDIR="$TMP_DIR/nested-native-replay" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$NATIVE_REPLAY" > "$NATIVE_REPLAY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: native bridge replay failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: log=$NATIVE_REPLAY_LOG" >&2
  exit 7
fi
if ! env TMPDIR="$TMP_DIR/nested-failure-continuity" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$FAILURE_CONTINUITY" > "$FAILURE_CONTINUITY_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: failure-domain continuity failed" >&2
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: log=$FAILURE_CONTINUITY_LOG" >&2
  exit 8
fi

required_owner_facts=(
  "explicit_approval_handoff_evidence_mesh_owner_present=true"
  "explicit_approval_gate_handoff_input=true"
  "handoff_packet_consistency_guard_required=true"
  "native_bridge_replay_guard_required=true"
  "failure_domain_continuity_guard_required=true"
  "verification_mesh_runner_required=true"
  "cross_packet_evidence_mesh_required=true"
  "metal_capability_separate_from_d3_approval=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "code_failure_domain=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing owner fact $fact" >&2
    exit 9
  fi
done

required_consistency_facts=(
  "route_classification=runtime_native_probe_explicit_approval_handoff_packet_consistency"
  "handoff_runner_passed=true"
  "handoff_packet_consistency_passed=true"
  "cross_packet_smoke_consistency_passed=true"
  "cross_packet_failure_domain_consistency_passed=true"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "code_failure_domain=false"
)
for fact in "${required_consistency_facts[@]}"; do
  if ! grep -F "$fact" "$CONSISTENCY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing consistency fact $fact" >&2
    exit 10
  fi
done

required_native_facts=(
  "route_classification=runtime_native_probe_explicit_approval_native_bridge_replay_guard"
  "route_scoped_native_bridge_evidence_passed=true"
  "native_bridge_package_link_probe_passed=true"
  "native_bridge_replay_guard_passed=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_native_facts[@]}"; do
  if ! grep -F "$fact" "$NATIVE_REPLAY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing native replay fact $fact" >&2
    exit 11
  fi
done

required_failure_facts=(
  "route_classification=runtime_native_probe_explicit_approval_failure_domain_continuity"
  "environment_drift_replay_passed=true"
  "failure_domain_continuity_guard_passed=true"
  "allowed_environment_classification_set=metal_capable_or_metal_unavailable"
  "required_next_actor=human_operator"
  "required_shell=explicitly_approved_shell"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "code_failure_domain=false"
)
for fact in "${required_failure_facts[@]}"; do
  if ! grep -F "$fact" "$FAILURE_CONTINUITY_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing failure continuity fact $fact" >&2
    exit 12
  fi
done

consistency_packet="$(grep -Eo 'packet_consistency_path=[^[:space:]]+' "$CONSISTENCY_LOG" | tail -1 | cut -d= -f2-)"
native_replay_packet="$(grep -Eo 'replay_packet_path=[^[:space:]]+' "$NATIVE_REPLAY_LOG" | tail -1 | cut -d= -f2-)"
continuity_packet="$(grep -Eo 'continuity_packet_path=[^[:space:]]+' "$FAILURE_CONTINUITY_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$consistency_packet" "$native_replay_packet" "$continuity_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: missing packet $packet" >&2
    exit 13
  fi
done

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$consistency_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$consistency_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$consistency_packet" | tail -1 | cut -d= -f2)"
environment_drift_between_probes="$(grep -Eo '^environment_drift_between_probes=(true|false)' "$continuity_packet" | tail -1 | cut -d= -f2)"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: protected path modified" >&2
  exit 14
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: public or foreign declaration diff found" >&2
  exit 15
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: forbidden production native bridge diff found" >&2
  exit 16
fi

{
  echo "explicit_approval_verification_mesh_version=1"
  echo "evidence_mesh_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "handoff_packet_consistency_passed=true"
  echo "consistency_log=$CONSISTENCY_LOG"
  echo "consistency_packet=$consistency_packet"
  echo "native_bridge_replay_guard_passed=true"
  echo "native_replay_log=$NATIVE_REPLAY_LOG"
  echo "native_replay_packet=$native_replay_packet"
  echo "failure_domain_continuity_guard_passed=true"
  echo "failure_continuity_log=$FAILURE_CONTINUITY_LOG"
  echo "continuity_packet=$continuity_packet"
  echo "explicit_approval_verification_mesh_runner_passed=true"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "environment_drift_between_probes=${environment_drift_between_probes:-false}"
  echo "required_next_actor=human_operator"
  echo "required_shell=explicitly_approved_shell"
  echo "d3_runtime_native_probe_approval_required=true"
  echo "approved_runtime_native_probe_execution_admitted=false"
  echo "metal_capable_shell_does_not_imply_approval=true"
  echo "code_failure_domain=false"
  echo "route_scoped_native_bridge_evidence_passed=true"
  echo "native_bridge_package_link_probe_passed=true"
  echo "handoff_packet_consistency_passed=true"
  echo "cross_packet_smoke_consistency_passed=true"
  echo "cross_packet_failure_domain_consistency_passed=true"
  echo "failure_domain_continuity_guard_passed=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$MESH_PACKET"

echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: route_classification=runtime_native_probe_explicit_approval_verification_mesh_runner"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: evidence_mesh_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: handoff_packet_consistency_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: native_bridge_replay_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: failure_domain_continuity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: explicit_approval_verification_mesh_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: mesh_packet_path=$MESH_PACKET"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: consistency_packet=$consistency_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: native_replay_packet=$native_replay_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: continuity_packet=$continuity_packet"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: environment_drift_between_probes=${environment_drift_between_probes:-false}"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: required_next_actor=human_operator"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: required_shell=explicitly_approved_shell"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: d3_runtime_native_probe_approval_required=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: approved_runtime_native_probe_execution_admitted=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: metal_capable_shell_does_not_imply_approval=true"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe explicit approval verification mesh runner: next_route=explicit_human_approved_d3_runtime_native_probe_execution_or_non_d3_mesh_rerun"
