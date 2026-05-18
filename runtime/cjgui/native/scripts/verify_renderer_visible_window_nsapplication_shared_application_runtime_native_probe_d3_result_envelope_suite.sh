#!/usr/bin/env zsh
#
# 维护注释：本脚本是 D3 result-envelope admission focused regression suite。
# 它串联 owner probe、fixture、classifier 与 source/build guard，确认当前 shell
# 只进入 result-envelope admission contract，不执行 runtime native probe。
# Truth: focused result-envelope suite；不消费 D3 approval，不执行 runtime native
# probe，不调用 application accessor，不创建 singleton，不扩 native bridge。
# Stop-line: 不创建或激活 NSApplication，不修改 activation policy，不运行 AppKit
# event loop / bounded pump，不执行 cleanup / teardown，不创建 visible window，不
# visible order，不取 drawable，不 render / commit / present / GPU submission，不改
# public API / production C ABI，不写 runtime_state.cj / cjpm.toml / renderer state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-probe-d3-result-envelope-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_admission_owner.sh"
FIXTURE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_fixture.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/d3-result-envelope-owner.log"
FIXTURE_LOG="$TMP_DIR/d3-result-envelope-fixture.log"
CLASSIFIER_LOG="$TMP_DIR/d3-result-envelope-classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/d3-result-envelope-source-build.log"
SUITE_PACKET="$TMP_DIR/d3-result-envelope-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$FIXTURE_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$FIXTURE_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing executable script $script" >&2
    exit 3
  fi
done
if [[ "${CJGUI_D3_RUNTIME_NATIVE_PROBE_APPROVED:-}" == "true" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: current suite route must not consume D3 approval" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/nested-owner" zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: log=$OWNER_LOG" >&2
  exit 5
fi
if ! env TMPDIR="$TMP_DIR/nested-fixture" zsh "$FIXTURE_SCRIPT" > "$FIXTURE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: fixture failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: log=$FIXTURE_LOG" >&2
  exit 6
fi

fixture_packet="$(grep -Eo 'fixture_packet_path=[^[:space:]]+' "$FIXTURE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$fixture_packet" || ! -f "$fixture_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing fixture packet $fixture_packet" >&2
  exit 7
fi

if ! env TMPDIR="$TMP_DIR/nested-classifier" CJGUI_D3_RESULT_ENVELOPE_FIXTURE_PACKET="$fixture_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: log=$CLASSIFIER_LOG" >&2
  exit 8
fi
if ! env TMPDIR="$TMP_DIR/nested-source-build" CJGUI_D3_RESULT_ENVELOPE_FIXTURE_PACKET="$fixture_packet" zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: log=$SOURCE_BUILD_LOG" >&2
  exit 9
fi

required_owner_facts=(
  "d3_result_envelope_admission_owner_present=true"
  "external_metal_capable_shell_packet_required=true"
  "external_approval_consumption_proof_required=true"
  "native_result_packet_schema_required=true"
  "no_production_truth_upgrade_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_owner_facts[@]}"; do
  if ! grep -F "$fact" "$OWNER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing owner fact $fact" >&2
    exit 10
  fi
done

required_fixture_facts=(
  "result_envelope_schema_fixture_ready=true"
  "current_shell_result_envelope_accepted=false"
  "current_shell_admission_pending_external_packet=true"
  "future_external_result_envelope_schema_admitted=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_fixture_facts[@]}"; do
  if ! grep -F "$fact" "$FIXTURE_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing fixture fact $fact" >&2
    exit 11
  fi
done

required_classifier_facts=(
  "result_envelope_admission_classifier_passed=true"
  "current_shell_result_envelope_admitted=false"
  "current_shell_admission_pending_external_packet=true"
  "future_external_result_envelope_schema_admitted=true"
  "external_result_envelope_required=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_classifier_facts[@]}"; do
  if ! grep -F "$fact" "$CLASSIFIER_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing classifier fact $fact" >&2
    exit 12
  fi
done

required_source_facts=(
  "d3_result_envelope_owner_probe_passed=true"
  "d3_result_envelope_fixture_ready=true"
  "d3_result_envelope_classifier_passed=true"
  "runtime_package_build_passed=true"
  "source_build_result_envelope_guard_passed=true"
  "current_shell_result_envelope_admitted=false"
  "future_external_result_envelope_schema_admitted=true"
  "runtime_native_probe_execution=false"
  "human_approved_d3_execution_consumed=false"
)
for fact in "${required_source_facts[@]}"; do
  if ! grep -F "$fact" "$SOURCE_BUILD_LOG" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing source/build fact $fact" >&2
    exit 13
  fi
done

classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
for packet in "$classifier_packet" "$source_build_packet"; do
  if [[ -z "$packet" || ! -f "$packet" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: missing packet $packet" >&2
    exit 14
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: protected path modified" >&2
  exit 15
fi

{
  echo "d3_result_envelope_suite_version=1"
  echo "d3_result_envelope_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_result_envelope_fixture_ready=true"
  echo "fixture_log=$FIXTURE_LOG"
  echo "fixture_packet=$fixture_packet"
  echo "d3_result_envelope_classifier_passed=true"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_result_envelope_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "runtime_package_build_passed=true"
  echo "d3_result_envelope_suite_passed=true"
  echo "current_shell_result_envelope_admitted=false"
  echo "current_shell_admission_pending_external_packet=true"
  echo "future_external_result_envelope_schema_admitted=true"
  echo "external_result_envelope_required=true"
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

echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: route_classification=d3_result_envelope_suite"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: d3_result_envelope_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: d3_result_envelope_fixture_ready=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: d3_result_envelope_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: source_build_result_envelope_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: runtime_package_build_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: d3_result_envelope_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: fixture_packet=$fixture_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: classifier_packet=$classifier_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: source_build_packet=$source_build_packet"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: current_shell_result_envelope_admitted=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: current_shell_admission_pending_external_packet=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: future_external_result_envelope_schema_admitted=true"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: human_approved_d3_execution_consumed=false"
echo "cjgui renderer NSApplication runtime native probe D3 result envelope suite: next_route=external_metal_capable_shell_result_envelope_or_renderer_state_planning"
