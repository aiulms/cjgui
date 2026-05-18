#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage104 bounded result-envelope admission 到
# renderer-state write-decision join focused suite。它同时验证 current-shell
# input 分类与 fixture-only admitted input 的正向 join 形状，并保持 renderer
# state write blocked。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-renderer-state-write-decision-join-suite"
ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_suite.sh"
WRITE_DECISION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_suite.sh"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_owner.sh"
FIXTURE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_admitted_fixture.sh"
JOIN_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_source_build_guard.sh"
ADMISSION_LOG="$TMP_DIR/current-admission.log"
WRITE_DECISION_LOG="$TMP_DIR/write-decision.log"
OWNER_LOG="$TMP_DIR/owner.log"
FIXTURE_LOG="$TMP_DIR/fixture.log"
CURRENT_JOIN_LOG="$TMP_DIR/current-join.log"
CURRENT_CLASSIFIER_LOG="$TMP_DIR/current-classifier.log"
FIXTURE_JOIN_LOG="$TMP_DIR/fixture-join.log"
FIXTURE_CLASSIFIER_LOG="$TMP_DIR/fixture-classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-renderer-state-write-decision-join-suite.packet"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$WRITE_DECISION_LOG"
: > "$OWNER_LOG"
: > "$FIXTURE_LOG"
: > "$CURRENT_JOIN_LOG"
: > "$CURRENT_CLASSIFIER_LOG"
: > "$FIXTURE_JOIN_LOG"
: > "$FIXTURE_CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$ADMISSION_SUITE_SCRIPT" "$WRITE_DECISION_SUITE_SCRIPT" "$OWNER_PROBE" "$FIXTURE_SCRIPT" "$JOIN_PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: missing executable script $script" >&2
    exit 3
  fi
done

if ! env TMPDIR="$TMP_DIR/current-admission" zsh "$ADMISSION_SUITE_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current admission suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$ADMISSION_LOG" >&2
  exit 4
fi
current_admission_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$current_admission_packet" || ! -f "$current_admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: missing current admission packet" >&2
  exit 5
fi

if ! env TMPDIR="$TMP_DIR/write-decision" zsh "$WRITE_DECISION_SUITE_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: write-decision suite failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$WRITE_DECISION_LOG" >&2
  exit 6
fi
write_decision_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_decision_packet" || ! -f "$write_decision_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: missing write-decision packet" >&2
  exit 7
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$OWNER_LOG" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/fixture" zsh "$FIXTURE_SCRIPT" > "$FIXTURE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: admitted fixture failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$FIXTURE_LOG" >&2
  exit 9
fi
fixture_packet="$(grep -Eo 'fixture_packet_path=[^[:space:]]+' "$FIXTURE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$fixture_packet" || ! -f "$fixture_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: missing fixture packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/current-join" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SUITE_PACKET="$current_admission_packet" \
  CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_SUITE_PACKET="$write_decision_packet" \
  zsh "$JOIN_PACKET_SCRIPT" > "$CURRENT_JOIN_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current join packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$CURRENT_JOIN_LOG" >&2
  exit 11
fi
current_join_packet="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$CURRENT_JOIN_LOG" | tail -1 | cut -d= -f2-)"

if ! env TMPDIR="$TMP_DIR/current-classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET="$current_join_packet" zsh "$CLASSIFIER_SCRIPT" > "$CURRENT_CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$CURRENT_CLASSIFIER_LOG" >&2
  exit 12
fi
current_classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CURRENT_CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"

if ! env TMPDIR="$TMP_DIR/fixture-join" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SUITE_PACKET="$fixture_packet" \
  CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_SUITE_PACKET="$write_decision_packet" \
  zsh "$JOIN_PACKET_SCRIPT" > "$FIXTURE_JOIN_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: fixture join packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$FIXTURE_JOIN_LOG" >&2
  exit 13
fi
fixture_join_packet="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$FIXTURE_JOIN_LOG" | tail -1 | cut -d= -f2-)"

if ! env TMPDIR="$TMP_DIR/fixture-classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET="$fixture_join_packet" zsh "$CLASSIFIER_SCRIPT" > "$FIXTURE_CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: fixture classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$FIXTURE_CLASSIFIER_LOG" >&2
  exit 14
fi
fixture_classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$FIXTURE_CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET="$fixture_join_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_CLASSIFIER_PACKET="$fixture_classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: log=$SOURCE_BUILD_LOG" >&2
  exit 15
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"

required_fixture_facts=(
  "guarded_write_decision_join_preflight_ready=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_fixture_facts[@]}"; do
  if ! grep -F "$fact" "$fixture_join_packet" "$fixture_classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: missing fixture fact $fact" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: protected path modified" >&2
  exit 17
fi

current_smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$current_admission_packet" | tail -1 | cut -d= -f2)"
current_bounded_admitted="$(grep -Eo '^bounded_result_envelope_admitted=(true|false)' "$current_admission_packet" | tail -1 | cut -d= -f2)"
current_join_ready="$(grep -Eo '^guarded_write_decision_join_preflight_ready=(true|false)' "$current_join_packet" | tail -1 | cut -d= -f2)"
current_runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$current_join_packet" | tail -1 | cut -d= -f2)"
fixture_join_ready="$(grep -Eo '^guarded_write_decision_join_preflight_ready=(true|false)' "$fixture_join_packet" | tail -1 | cut -d= -f2)"

{
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_suite_version=1"
  echo "current_admission_log=$ADMISSION_LOG"
  echo "current_admission_packet=$current_admission_packet"
  echo "write_decision_log=$WRITE_DECISION_LOG"
  echo "write_decision_packet=$write_decision_packet"
  echo "owner_log=$OWNER_LOG"
  echo "fixture_log=$FIXTURE_LOG"
  echo "fixture_packet=$fixture_packet"
  echo "current_join_log=$CURRENT_JOIN_LOG"
  echo "current_join_packet=$current_join_packet"
  echo "current_classifier_log=$CURRENT_CLASSIFIER_LOG"
  echo "current_classifier_packet=$current_classifier_packet"
  echo "fixture_join_log=$FIXTURE_JOIN_LOG"
  echo "fixture_join_packet=$fixture_join_packet"
  echo "fixture_classifier_log=$FIXTURE_CLASSIFIER_LOG"
  echo "fixture_classifier_packet=$fixture_classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_fixture_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_current_packet_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_current_classifier_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_fixture_packet_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_fixture_classifier_passed=true"
  echo "source_build_join_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_suite_passed=true"
  echo "current_shell_smoke_environment_classification=$current_smoke_classification"
  echo "current_shell_bounded_result_envelope_admitted=$current_bounded_admitted"
  echo "current_shell_guarded_write_decision_join_preflight_ready=$current_join_ready"
  echo "fixture_guarded_write_decision_join_preflight_ready=$fixture_join_ready"
  echo "join_preflight_is_not_renderer_state_write_permission=true"
  echo "production_write_admission_after_join_preflight_required=true"
  echo "renderer_state_write_after_join_preflight_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$current_runtime_native_probe_execution"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "production_public_c_abi_added=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: route_classification=d3_bounded_result_envelope_renderer_state_write_decision_join_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: d3_bounded_result_envelope_renderer_state_write_decision_join_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current_shell_smoke_environment_classification=$current_smoke_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current_shell_bounded_result_envelope_admitted=$current_bounded_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: current_shell_guarded_write_decision_join_preflight_ready=$current_join_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: fixture_guarded_write_decision_join_preflight_ready=$fixture_join_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: renderer_state_write_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join suite: renderer_state_write=false"
