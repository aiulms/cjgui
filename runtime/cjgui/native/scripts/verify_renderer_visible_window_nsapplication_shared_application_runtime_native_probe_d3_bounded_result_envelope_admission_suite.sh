#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage103 D3 bounded result-envelope admission focused
# suite。它先复用 stage102 bounded route 生成真实 result envelope，再把同一个
# envelope/schema/classifier 传给 source/build guard，避免重复 native probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-admission-suite"
ENVIRONMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_environment_packet.sh"
RESULT_ENVELOPE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_result_envelope.sh"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_owner.sh"
SCHEMA_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_schema.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_source_build_guard.sh"
ENVIRONMENT_LOG="$TMP_DIR/environment.log"
RESULT_ENVELOPE_LOG="$TMP_DIR/result-envelope.log"
OWNER_LOG="$TMP_DIR/owner.log"
SCHEMA_LOG="$TMP_DIR/schema.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-admission-suite.packet"

mkdir -p "$TMP_DIR"
: > "$ENVIRONMENT_LOG"
: > "$RESULT_ENVELOPE_LOG"
: > "$OWNER_LOG"
: > "$SCHEMA_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$ENVIRONMENT_PACKET_SCRIPT" "$RESULT_ENVELOPE_SCRIPT" "$OWNER_PROBE" "$SCHEMA_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing executable script $script" >&2
    exit 3
  fi
done

if ! env TMPDIR="$TMP_DIR/environment" zsh "$ENVIRONMENT_PACKET_SCRIPT" > "$ENVIRONMENT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: environment packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$ENVIRONMENT_LOG" >&2
  exit 4
fi
environment_packet="$(grep -Eo 'environment_packet_path=[^[:space:]]+' "$ENVIRONMENT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$environment_packet" || ! -f "$environment_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing environment packet" >&2
  exit 5
fi

if ! env TMPDIR="$TMP_DIR/result-envelope" CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET="$environment_packet" zsh "$RESULT_ENVELOPE_SCRIPT" > "$RESULT_ENVELOPE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: result envelope failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$RESULT_ENVELOPE_LOG" >&2
  exit 6
fi
result_envelope="$(grep -Eo 'result_envelope_path=[^[:space:]]+' "$RESULT_ENVELOPE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$result_envelope" || ! -f "$result_envelope" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing result envelope" >&2
  exit 7
fi

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$OWNER_LOG" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/schema" CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE="$result_envelope" zsh "$SCHEMA_SCRIPT" > "$SCHEMA_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: schema failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$SCHEMA_LOG" >&2
  exit 9
fi
schema_packet="$(grep -Eo 'schema_packet_path=[^[:space:]]+' "$SCHEMA_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$schema_packet" || ! -f "$schema_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing schema packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/classifier" CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SCHEMA_PACKET="$schema_packet" zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$CLASSIFIER_LOG" >&2
  exit 11
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing classifier packet" >&2
  exit 12
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE="$result_envelope" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SCHEMA_PACKET="$schema_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: log=$SOURCE_BUILD_LOG" >&2
  exit 13
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: missing source/build packet" >&2
  exit 14
fi

bounded_result_envelope_admitted="$(grep -Eo '^bounded_result_envelope_admitted=(true|false)' "$classifier_packet" | tail -1 | cut -d= -f2)"
runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$classifier_packet" | tail -1 | cut -d= -f2)"
smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$schema_packet" | tail -1 | cut -d= -f2)"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: protected path modified" >&2
  exit 15
fi

{
  echo "d3_bounded_result_envelope_admission_suite_version=1"
  echo "environment_log=$ENVIRONMENT_LOG"
  echo "environment_packet=$environment_packet"
  echo "result_envelope_log=$RESULT_ENVELOPE_LOG"
  echo "result_envelope=$result_envelope"
  echo "owner_log=$OWNER_LOG"
  echo "schema_log=$SCHEMA_LOG"
  echo "schema_packet=$schema_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_admission_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_admission_schema_passed=true"
  echo "d3_bounded_result_envelope_admission_classifier_passed=true"
  echo "source_build_guard_passed=true"
  echo "d3_bounded_result_envelope_admission_suite_passed=true"
  echo "smoke_environment_classification=$smoke_classification"
  echo "bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "renderer_state_write_after_admission_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: route_classification=d3_bounded_result_envelope_admission_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: d3_bounded_result_envelope_admission_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: d3_bounded_result_envelope_admission_schema_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: d3_bounded_result_envelope_admission_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: source_build_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: d3_bounded_result_envelope_admission_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: runtime_native_probe_execution=$runtime_native_probe_execution"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission suite: renderer_state_write=false"
