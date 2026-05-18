#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage102 D3 bounded runtime execution focused suite。
# 它只分类一次 environment packet，并把同一个 packet 传给 result envelope 与
# source/build guard，避免在非 Metal shell 中反复堆同构 recovery。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-runtime-execution-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_owner.sh"
ENVIRONMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_environment_packet.sh"
RESULT_ENVELOPE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_result_envelope.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_runtime_execution_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/owner.log"
ENVIRONMENT_LOG="$TMP_DIR/environment.log"
RESULT_ENVELOPE_LOG="$TMP_DIR/result-envelope.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-runtime-execution-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$ENVIRONMENT_LOG"
: > "$RESULT_ENVELOPE_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$ENVIRONMENT_PACKET_SCRIPT" "$RESULT_ENVELOPE_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: missing executable script $script" >&2
    exit 3
  fi
done

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: log=$OWNER_LOG" >&2
  exit 4
fi

if ! env TMPDIR="$TMP_DIR/environment" zsh "$ENVIRONMENT_PACKET_SCRIPT" > "$ENVIRONMENT_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: environment packet failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: log=$ENVIRONMENT_LOG" >&2
  exit 5
fi
environment_packet="$(grep -Eo 'environment_packet_path=[^[:space:]]+' "$ENVIRONMENT_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$environment_packet" || ! -f "$environment_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: missing environment packet" >&2
  exit 6
fi

if ! env TMPDIR="$TMP_DIR/result-envelope" CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET="$environment_packet" zsh "$RESULT_ENVELOPE_SCRIPT" > "$RESULT_ENVELOPE_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: result envelope failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: log=$RESULT_ENVELOPE_LOG" >&2
  exit 7
fi
result_envelope="$(grep -Eo 'result_envelope_path=[^[:space:]]+' "$RESULT_ENVELOPE_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$result_envelope" || ! -f "$result_envelope" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: missing result envelope" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_ENVIRONMENT_PACKET="$environment_packet" \
  CJGUI_D3_BOUNDED_RUNTIME_EXECUTION_RESULT_ENVELOPE="$result_envelope" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: log=$SOURCE_BUILD_LOG" >&2
  exit 9
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: missing source/build packet" >&2
  exit 10
fi

required_result_facts=(
  "d3_bounded_runtime_execution_result_envelope_version=1"
  "result_envelope_semantics_passed=true"
  "result_envelope_is_not_production_truth=true"
  "renderer_state_write=false"
)
for fact in "${required_result_facts[@]}"; do
  if ! grep -F "$fact" "$result_envelope" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: missing result fact $fact" >&2
    exit 11
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: protected path modified" >&2
  exit 12
fi

smoke_classification="$(grep -Eo '^smoke_environment_classification=[A-Za-z0-9_]+' "$result_envelope" | tail -1 | cut -d= -f2)"
runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$result_envelope" | tail -1 | cut -d= -f2)"
bounded_probe_should_execute="$(grep -Eo '^bounded_d3_runtime_native_probe_should_execute=(true|false)' "$result_envelope" | tail -1 | cut -d= -f2)"

{
  echo "d3_bounded_runtime_execution_suite_version=1"
  echo "d3_bounded_runtime_execution_owner_probe_passed=true"
  echo "owner_log=$OWNER_LOG"
  echo "d3_bounded_runtime_execution_environment_packet_passed=true"
  echo "environment_log=$ENVIRONMENT_LOG"
  echo "environment_packet=$environment_packet"
  echo "d3_bounded_runtime_execution_result_envelope_passed=true"
  echo "result_envelope_log=$RESULT_ENVELOPE_LOG"
  echo "result_envelope=$result_envelope"
  echo "source_build_guard_passed=true"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_runtime_execution_suite_passed=true"
  echo "smoke_environment_classification=$smoke_classification"
  echo "bounded_d3_runtime_native_probe_should_execute=$bounded_probe_should_execute"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: route_classification=d3_bounded_runtime_execution_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: d3_bounded_runtime_execution_owner_probe_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: d3_bounded_runtime_execution_environment_packet_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: d3_bounded_runtime_execution_result_envelope_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: source_build_guard_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: d3_bounded_runtime_execution_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: smoke_environment_classification=$smoke_classification"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: bounded_d3_runtime_native_probe_should_execute=$bounded_probe_should_execute"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: runtime_native_probe_execution=$runtime_native_probe_execution"
echo "cjgui renderer NSApplication runtime native probe D3 bounded runtime execution suite: renderer_state_write=false"
