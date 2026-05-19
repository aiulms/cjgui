#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage118 first-frame observation truth-admission join
# focused suite。它串联 owner、packet、classifier 与 source/build guard，
# 产出 renderer-state write admission 下一段可消费的 suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage118-first-frame-observation-truth-admission-join-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-truth-admission-join-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"
join_packet=""
classifier_packet=""
source_build_packet=""

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: owner probe failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner_present=true"
require_file_fact "$OWNER_LOG" "positive_first_frame_observed_envelope_input_required=true"
require_file_fact "$OWNER_LOG" "frame_hash_summary_before_truth_admission_required=true"
require_file_fact "$OWNER_LOG" "independent_write_decision_contract_input_required=true"
require_file_fact "$OWNER_LOG" "truth_admission_join_is_not_production_render_truth=true"
require_file_fact "$OWNER_LOG" "production_truth_admission_after_join_preflight_required=true"
require_file_fact "$OWNER_LOG" "production_write_admission_after_truth_admission_join_required=true"
require_file_fact "$OWNER_LOG" "production_render_truth_after_join_preflight_allowed=false"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: packet generation failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: log=$PACKET_LOG" >&2
  exit 7
fi
join_packet="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$join_packet" || ! -f "$join_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing join packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_PACKET="$join_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: classifier failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_PACKET="$join_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: source/build guard failed" >&2
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing source build packet" >&2
  exit 12
fi

required_suite_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_passed=true"
  "source_build_first_frame_observation_truth_admission_join_guard_passed=true"
  "runtime_package_build_passed=true"
  "positive_first_frame_observation_input_ready=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "truth_admission_join_is_not_production_render_truth=true"
  "production_truth_admission_after_join_preflight_required=true"
  "production_write_admission_after_truth_admission_join_required=true"
  "production_render_truth_after_join_preflight_allowed=false"
  "renderer_state_write_after_truth_admission_join_allowed=false"
  "production_render_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$join_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: protected path modified" >&2
  exit 14
fi

stage117_ready="$(fact_value "$join_packet" "stage117_current_shell_first_frame_observation_first_slice_ready")"
stage117_executed="$(fact_value "$join_packet" "stage117_bounded_first_frame_observation_first_slice_executed")"
stage117_failure_classification="$(fact_value "$join_packet" "stage117_first_frame_observation_first_slice_failure_classification")"
stage117_classifier_route="$(fact_value "$join_packet" "stage117_first_frame_observation_first_slice_classifier_route")"
current_rerun_ready="$(fact_value "$join_packet" "current_shell_first_frame_observation_rerun_ready")"
current_rerun_failure_classification="$(fact_value "$join_packet" "current_shell_first_frame_observation_rerun_failure_classification")"
positive_suite_packet_source="$(fact_value "$join_packet" "first_frame_positive_suite_packet_source")"
first_frame_observed="$(fact_value "$join_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$join_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$join_packet" "frame_hash_nonzero")"
positive_input="$(fact_value "$join_packet" "positive_first_frame_observation_input_ready")"
classifier_route="$(fact_value "$classifier_packet" "first_frame_observation_truth_admission_join_classifier_route")"
join_ready="$(fact_value "$join_packet" "first_frame_observation_truth_admission_join_preflight_ready")"
runtime_native_probe_execution="$(fact_value "$join_packet" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "join_packet=$join_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_passed=true"
  echo "source_build_first_frame_observation_truth_admission_join_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite_passed=true"
  echo "current_shell_first_frame_observation_rerun_ready=$current_rerun_ready"
  echo "current_shell_first_frame_observation_rerun_failure_classification=$current_rerun_failure_classification"
  echo "first_frame_positive_suite_packet_source=$positive_suite_packet_source"
  echo "stage117_current_shell_first_frame_observation_first_slice_ready=$stage117_ready"
  echo "stage117_bounded_first_frame_observation_first_slice_executed=$stage117_executed"
  echo "stage117_first_frame_observation_first_slice_failure_classification=$stage117_failure_classification"
  echo "stage117_first_frame_observation_first_slice_classifier_route=$stage117_classifier_route"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "positive_first_frame_observation_input_ready=$positive_input"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "first_frame_observation_truth_admission_join_classifier_route=$classifier_route"
  echo "first_frame_observation_truth_admission_join_preflight_ready=$join_ready"
  echo "isolated_first_frame_observation_bound_to_write_decision_contract=$join_ready"
  echo "truth_admission_join_is_not_production_render_truth=true"
  echo "production_truth_admission_after_join_preflight_required=true"
  echo "production_write_admission_after_truth_admission_join_required=true"
  echo "production_render_truth_after_join_preflight_allowed=false"
  echo "renderer_state_write_after_truth_admission_join_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: route_classification=d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: first_frame_observation_truth_admission_join_classifier_route=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join suite: renderer_state_write=false"
