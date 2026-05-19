#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage121 state-update dry-run envelope first-slice focused
# suite。它串联 owner、packet、classifier 与 source/build guard，产出下一段
# baseline / semantic verification 可消费的 packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage121-renderer-state-update-dry-run-envelope-first-slice-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-update-dry-run-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"
state_update_packet=""
classifier_packet=""
source_build_packet=""

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer state-update dry-run envelope suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer state-update dry-run envelope suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer state-update dry-run envelope suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui renderer state-update dry-run envelope suite: owner probe failed" >&2
  echo "cjgui renderer state-update dry-run envelope suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "renderer_state_update_dry_run_envelope_first_slice_owner_present=true"
require_file_fact "$OWNER_LOG" "renderer_state_update_dry_run_envelope_ready=true"
require_file_fact "$OWNER_LOG" "renderer_state_write=false"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui renderer state-update dry-run envelope suite: packet generation failed" >&2
  echo "cjgui renderer state-update dry-run envelope suite: log=$PACKET_LOG" >&2
  exit 7
fi
state_update_packet="$(grep -Eo 'state_update_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$state_update_packet" || ! -f "$state_update_packet" ]]; then
  echo "cjgui renderer state-update dry-run envelope suite: missing state-update packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_PACKET="$state_update_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui renderer state-update dry-run envelope suite: classifier failed" >&2
  echo "cjgui renderer state-update dry-run envelope suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui renderer state-update dry-run envelope suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_PACKET="$state_update_packet" \
  CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui renderer state-update dry-run envelope suite: source/build guard failed" >&2
  echo "cjgui renderer state-update dry-run envelope suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui renderer state-update dry-run envelope suite: missing source build packet" >&2
  exit 12
fi

required_suite_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet_passed=true"
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier_passed=true"
  "source_build_renderer_state_update_dry_run_envelope_first_slice_guard_passed=true"
  "runtime_package_build_passed=true"
  "renderer_state_update_dry_run_envelope_ready=true"
  "state_update_envelope_dry_run_only=true"
  "production_write_preflight_mapped_to_state_update_candidate=true"
  "first_frame_observation_state_field_mapped=true"
  "frame_hash_summary_state_field_mapped=true"
  "baseline_gate_state_field_mapped=true"
  "rollback_visibility_boundary_state_field_mapped=true"
  "state_mutation_request_fail_closed=true"
  "visibility_publication_fail_closed=true"
  "rollback_fallback_write_fail_closed=true"
  "frame_hash_value_persisted=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_suite_facts[@]}"; do
  if ! grep -F "$fact" "$state_update_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui renderer state-update dry-run envelope suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope suite: protected path modified" >&2
  exit 14
fi

dry_run_source="$(fact_value "$state_update_packet" "dry_run_admission_positive_suite_packet_source")"
current_dry_run_rerun_ready="$(fact_value "$state_update_packet" "current_shell_dry_run_admission_rerun_ready")"
current_dry_run_rerun_failure="$(fact_value "$state_update_packet" "current_shell_dry_run_admission_rerun_failure_classification")"
write_source="$(fact_value "$state_update_packet" "production_write_admission_positive_suite_packet_source")"
first_frame_source="$(fact_value "$state_update_packet" "first_frame_positive_suite_packet_source")"
runtime_native_probe_execution="$(fact_value "$state_update_packet" "runtime_native_probe_execution")"
classifier_route="$(fact_value "$classifier_packet" "renderer_state_update_dry_run_envelope_classifier_route")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "state_update_packet=$state_update_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier_passed=true"
  echo "source_build_renderer_state_update_dry_run_envelope_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite_passed=true"
  echo "dry_run_admission_positive_suite_packet_source=$dry_run_source"
  echo "current_shell_dry_run_admission_rerun_ready=$current_dry_run_rerun_ready"
  echo "current_shell_dry_run_admission_rerun_failure_classification=$current_dry_run_rerun_failure"
  echo "production_write_admission_positive_suite_packet_source=$write_source"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "renderer_state_update_dry_run_envelope_classifier_route=$classifier_route"
  echo "renderer_state_update_dry_run_envelope_ready=true"
  echo "state_update_envelope_dry_run_only=true"
  echo "production_write_preflight_mapped_to_state_update_candidate=true"
  echo "first_frame_observation_state_field_mapped=true"
  echo "frame_hash_summary_state_field_mapped=true"
  echo "baseline_gate_state_field_mapped=true"
  echo "rollback_visibility_boundary_state_field_mapped=true"
  echo "state_mutation_request_fail_closed=true"
  echo "visibility_publication_fail_closed=true"
  echo "rollback_fallback_write_fail_closed=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "state_mutation_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
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

echo "cjgui renderer state-update dry-run envelope suite: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite"
echo "cjgui renderer state-update dry-run envelope suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui renderer state-update dry-run envelope suite: d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite_passed=true"
echo "cjgui renderer state-update dry-run envelope suite: renderer_state_update_dry_run_envelope_classifier_route=$classifier_route"
echo "cjgui renderer state-update dry-run envelope suite: renderer_state_write=false"
