#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage120 first-frame observation production write
# admission first-slice focused suite。它串联 owner、packet、classifier 与
# source/build guard，产出下一段 renderer-state write dry-run / state-update
# admission 可消费的 packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage120-first-frame-observation-production-write-admission-first-slice-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-production-write-admission-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"
write_admission_packet=""
classifier_packet=""
source_build_packet=""

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_owner_present=true"
require_file_fact "$OWNER_LOG" "production_render_truth_admission_ready_input=true"
require_file_fact "$OWNER_LOG" "production_write_admission_preflight_ready=true"
require_file_fact "$OWNER_LOG" "production_write_admission_preflight_only=true"
require_file_fact "$OWNER_LOG" "baseline_or_semantic_verification_before_renderer_state_write_required=true"
require_file_fact "$OWNER_LOG" "result_envelope_promoted_to_production_truth=false"
require_file_fact "$OWNER_LOG" "production_render_truth=false"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: packet generation failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: log=$PACKET_LOG" >&2
  exit 7
fi
write_admission_packet="$(grep -Eo 'write_admission_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$write_admission_packet" || ! -f "$write_admission_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing write admission packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_WRITE_ADMISSION_FIRST_SLICE_PACKET="$write_admission_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_WRITE_ADMISSION_FIRST_SLICE_PACKET="$write_admission_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_WRITE_ADMISSION_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing source build packet" >&2
  exit 12
fi

required_suite_facts=(
  "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet_passed=true"
  "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier_passed=true"
  "source_build_first_frame_observation_production_write_admission_first_slice_guard_passed=true"
  "runtime_package_build_passed=true"
  "production_render_truth_admission_ready=true"
  "production_write_admission_preflight_ready=true"
  "production_write_admission_preflight_only=true"
  "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  "renderer_state_write_after_production_truth_admission_allowed=false"
  "renderer_state_write_after_production_write_admission_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$write_admission_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: protected path modified" >&2
  exit 14
fi

truth_source="$(fact_value "$write_admission_packet" "production_truth_admission_positive_suite_packet_source")"
current_truth_admission_ready="$(fact_value "$write_admission_packet" "current_shell_production_truth_admission_rerun_ready")"
current_truth_admission_failure="$(fact_value "$write_admission_packet" "current_shell_production_truth_admission_rerun_failure_classification")"
truth_join_source="$(fact_value "$write_admission_packet" "truth_admission_join_positive_suite_packet_source")"
current_truth_join_rerun_ready="$(fact_value "$write_admission_packet" "current_shell_truth_admission_join_rerun_ready")"
current_truth_join_rerun_failure_classification="$(fact_value "$write_admission_packet" "current_shell_truth_admission_join_rerun_failure_classification")"
first_frame_source="$(fact_value "$write_admission_packet" "first_frame_positive_suite_packet_source")"
current_first_frame_rerun_ready="$(fact_value "$write_admission_packet" "current_shell_first_frame_observation_rerun_ready")"
current_first_frame_rerun_failure_classification="$(fact_value "$write_admission_packet" "current_shell_first_frame_observation_rerun_failure_classification")"
production_truth_ready="$(fact_value "$write_admission_packet" "production_render_truth_admission_ready")"
production_write_ready="$(fact_value "$write_admission_packet" "production_write_admission_preflight_ready")"
first_frame_observed="$(fact_value "$write_admission_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$write_admission_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$write_admission_packet" "frame_hash_nonzero")"
classifier_route="$(fact_value "$classifier_packet" "first_frame_observation_production_write_admission_classifier_route")"
runtime_native_probe_execution="$(fact_value "$write_admission_packet" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "write_admission_packet=$write_admission_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier_passed=true"
  echo "source_build_first_frame_observation_production_write_admission_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite_passed=true"
  echo "production_truth_admission_positive_suite_packet_source=$truth_source"
  echo "current_shell_production_truth_admission_rerun_ready=$current_truth_admission_ready"
  echo "current_shell_production_truth_admission_rerun_failure_classification=$current_truth_admission_failure"
  echo "truth_admission_join_positive_suite_packet_source=$truth_join_source"
  echo "current_shell_truth_admission_join_rerun_ready=$current_truth_join_rerun_ready"
  echo "current_shell_truth_admission_join_rerun_failure_classification=$current_truth_join_rerun_failure_classification"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "current_shell_first_frame_observation_rerun_ready=$current_first_frame_rerun_ready"
  echo "current_shell_first_frame_observation_rerun_failure_classification=$current_first_frame_rerun_failure_classification"
  echo "production_render_truth_admission_ready=$production_truth_ready"
  echo "production_write_admission_preflight_ready=$production_write_ready"
  echo "production_write_admission_preflight_only=true"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  echo "first_frame_observation_production_write_admission_classifier_route=$classifier_route"
  echo "renderer_state_write_after_production_truth_admission_allowed=false"
  echo "renderer_state_write_after_production_write_admission_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SUITE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: route_classification=d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: first_frame_observation_production_write_admission_classifier_route=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission suite: renderer_state_write=false"
