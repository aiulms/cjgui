#!/usr/bin/env zsh
#
# 维护注释：本脚本是 runtime native-readiness non-D3 rerun maintenance 的
# aggregate guard。它 fresh rerun orchestration runner，并追加 protected path、
# public/foreign surface 与 production native bridge forbidden diff scans。
# Truth: related regression guards aggregation；不执行 runtime native probe，不消费
# D3 approval，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 nextDrawable，不 render / commit / present / GPU submission，
# 不改 public API / production C ABI，不写 runtime_state.cj / cjpm.toml /
# renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-non-d3-maintenance-aggregate"
CLANG_CACHE_DIR="$TMP_DIR/clang-module-cache"
ORCHESTRATION_RUNNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_non_d3_orchestration_runner.sh"
ORCHESTRATION_LOG="$TMP_DIR/non-d3-orchestration-runner.log"
AGGREGATE_PACKET="$TMP_DIR/non-d3-maintenance-aggregate.packet"

mkdir -p "$TMP_DIR" "$CLANG_CACHE_DIR"
: > "$ORCHESTRATION_LOG"
: > "$AGGREGATE_PACKET"

if [[ ! -x "$ORCHESTRATION_RUNNER" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: missing executable orchestration runner $ORCHESTRATION_RUNNER" >&2
  exit 3
fi
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: this script does not consume D3 runtime native probe approval" >&2
  exit 4
fi

if ! env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" zsh "$ORCHESTRATION_RUNNER" > "$ORCHESTRATION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: orchestration runner failed" >&2
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: log=$ORCHESTRATION_LOG" >&2
  exit 5
fi

required_orchestration_facts=(
  "route_classification=runtime_native_probe_non_d3_orchestration_runner"
  "non_d3_owner_probe_passed=true"
  "packet_integrity_guard_passed=true"
  "failure_domain_replay_passed=true"
  "non_d3_orchestration_runner_passed=true"
  "runtime_package_build_passed=true"
  "source_build_probe_evidence_strengthened=true"
  "focused_regression_suite_rerun_passed=true"
  "anchored_packet_integrity_guard_passed=true"
  "automation_can_continue_non_d3_recovery=true"
  "code_failure_domain=false"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
  "application_singleton_accessor_call=false"
  "native_bridge_expansion=false"
  "protected_path_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
)

for fact in "${required_orchestration_facts[@]}"; do
  if ! grep -F "$fact" "$ORCHESTRATION_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: missing orchestration fact $fact" >&2
    exit 6
  fi
done

orchestration_packet="$(grep -Eo 'orchestration_packet_path=[^[:space:]]+' "$ORCHESTRATION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$orchestration_packet" || ! -f "$orchestration_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: missing orchestration packet" >&2
  exit 7
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: protected path modified" >&2
  exit 8
fi

if git -C "$REPO_DIR" diff -U0 -- '*.cj' \
  | grep -E '^\+' \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: public or foreign declaration diff found" >&2
  exit 9
fi

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: forbidden production native bridge diff found" >&2
  exit 10
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$orchestration_packet" | tail -1 | cut -d= -f2)"
smoke_exit_code="$(grep -Eo '^smoke_exit_code=[0-9]+' "$orchestration_packet" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$orchestration_packet" | tail -1 | cut -d= -f2)"
required_shell="$(grep -Eo '^required_shell=[A-Za-z0-9_]+' "$orchestration_packet" | tail -1 | cut -d= -f2)"

{
  echo "non_d3_maintenance_aggregate_version=1"
  echo "orchestration_runner_passed=true"
  echo "orchestration_runner_log=$ORCHESTRATION_LOG"
  echo "orchestration_packet=$orchestration_packet"
  echo "protected_path_scan_passed=true"
  echo "public_foreign_surface_scan_passed=true"
  echo "production_native_bridge_forbidden_scan_passed=true"
  echo "non_d3_maintenance_aggregate_guard_passed=true"
  echo "smoke_exit_code=$smoke_exit_code"
  echo "smoke_environment_classification=$smoke_classification"
  echo "failure_domain=$failure_domain"
  echo "required_shell=$required_shell"
  echo "code_failure_domain=false"
  echo "runtime_package_build_passed=true"
  echo "source_build_probe_evidence_strengthened=true"
  echo "focused_regression_suite_rerun_passed=true"
  echo "anchored_packet_integrity_guard_passed=true"
  echo "failure_domain_replay_passed=true"
  echo "related_regression_guards_aggregated=true"
  echo "automation_can_continue_non_d3_recovery=true"
  echo "runtime_native_probe_execution=false"
  echo "human_approved_d3_execution_consumed=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$AGGREGATE_PACKET"

echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: route_classification=runtime_native_probe_non_d3_maintenance_aggregate_guard"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: orchestration_runner_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: protected_path_scan_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: public_foreign_surface_scan_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: production_native_bridge_forbidden_scan_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: non_d3_maintenance_aggregate_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: aggregate_packet_path=$AGGREGATE_PACKET"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: orchestration_packet=$orchestration_packet"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: smoke_exit_code=$smoke_exit_code"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: failure_domain=$failure_domain"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: required_shell=$required_shell"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: code_failure_domain=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: source_build_probe_evidence_strengthened=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: focused_regression_suite_rerun_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: anchored_packet_integrity_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: failure_domain_replay_passed=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: related_regression_guards_aggregated=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: automation_can_continue_non_d3_recovery=true"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: native_bridge_expansion=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: protected_path_modified=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: renderer_state_write=false"
echo "cjgui renderer NSApplication runtime native probe non-D3 maintenance aggregate guard: next_route=human_approved_d3_runtime_native_probe_execution_or_non_d3_maintenance_rerun"
