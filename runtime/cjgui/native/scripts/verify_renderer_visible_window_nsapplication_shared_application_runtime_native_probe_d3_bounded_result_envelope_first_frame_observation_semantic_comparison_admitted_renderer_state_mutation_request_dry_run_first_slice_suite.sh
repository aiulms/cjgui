#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage126 renderer-state mutation request dry-run focused
# suite。它串联 owner、packet、classifier 与 source/build guard。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-suite"
OWNER_PROBE="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet.sh"
CLASSIFIER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier.sh"
SOURCE_BUILD_GUARD="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_source_build_guard.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_LOG="$TMP_DIR/classifier.log"
SOURCE_BUILD_LOG="$TMP_DIR/source-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$CLASSIFIER_LOG"
: > "$SOURCE_BUILD_LOG"
: > "$SUITE_PACKET"

for script in "$OWNER_PROBE" "$PACKET_SCRIPT" "$CLASSIFIER_SCRIPT" "$SOURCE_BUILD_GUARD"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui semantic-comparison-admitted mutation request suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui semantic-comparison-admitted mutation request suite: syntax check failed $script" >&2
    exit 4
  fi
done

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$OWNER_PROBE" > "$OWNER_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request suite: owner probe failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request suite: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true"

if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request suite: packet generation failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request suite: log=$PACKET_LOG" >&2
  exit 7
fi
mutation_request_packet="$(grep -Eo 'semantic_comparison_admitted_mutation_request_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$mutation_request_packet" || ! -f "$mutation_request_packet" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request suite: missing mutation request packet" >&2
  exit 8
fi

if ! env TMPDIR="$TMP_DIR/classifier" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_PACKET="$mutation_request_packet" \
  zsh "$CLASSIFIER_SCRIPT" > "$CLASSIFIER_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request suite: classifier failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request suite: log=$CLASSIFIER_LOG" >&2
  exit 9
fi
classifier_packet="$(grep -Eo 'classifier_packet_path=[^[:space:]]+' "$CLASSIFIER_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$classifier_packet" || ! -f "$classifier_packet" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request suite: missing classifier packet" >&2
  exit 10
fi

if ! env TMPDIR="$TMP_DIR/source-build" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_PACKET="$mutation_request_packet" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_CLASSIFIER_PACKET="$classifier_packet" \
  zsh "$SOURCE_BUILD_GUARD" > "$SOURCE_BUILD_LOG" 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request suite: source/build guard failed" >&2
  echo "cjgui semantic-comparison-admitted mutation request suite: log=$SOURCE_BUILD_LOG" >&2
  exit 11
fi
source_build_packet="$(grep -Eo 'source_build_packet_path=[^[:space:]]+' "$SOURCE_BUILD_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$source_build_packet" || ! -f "$source_build_packet" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request suite: missing source build packet" >&2
  exit 12
fi

for fact in \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true" \
  "renderer_state_mutation_request_shape_defined=true" \
  "decision_denial_bound_to_mutation_request_rejection=true" \
  "mutation_request_non_executable=true" \
  "mutation_request_dry_run_only=true" \
  "renderer_state_mutation_request_rejected=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "runtime_package_build_passed=true"; do
  if ! grep -F "$fact" "$mutation_request_packet" "$classifier_packet" "$source_build_packet" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request suite: missing fact $fact" >&2
    exit 13
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request suite: protected path modified" >&2
  exit 14
fi

classifier_route="$(fact_value "$classifier_packet" "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route")"
runtime_native_probe_execution="$(fact_value "$mutation_request_packet" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "mutation_request_packet=$mutation_request_packet"
  echo "classifier_log=$CLASSIFIER_LOG"
  echo "classifier_packet=$classifier_packet"
  echo "source_build_log=$SOURCE_BUILD_LOG"
  echo "source_build_packet=$source_build_packet"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier_passed=true"
  echo "source_build_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_guard_passed=true"
  echo "runtime_package_build_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite_passed=true"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=$classifier_route"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true"
  echo "renderer_state_mutation_request_shape_defined=true"
  echo "decision_denial_bound_to_mutation_request_rejection=true"
  echo "future_mutation_boundary_bound_to_request_stop_line=true"
  echo "mutation_request_non_executable=true"
  echo "mutation_request_dry_run_only=true"
  echo "renderer_state_mutation_request_rejected=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
} > "$SUITE_PACKET"

echo "cjgui semantic-comparison-admitted mutation request suite: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite"
echo "cjgui semantic-comparison-admitted mutation request suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui semantic-comparison-admitted mutation request suite: d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite_passed=true"
echo "cjgui semantic-comparison-admitted mutation request suite: semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic-comparison-admitted mutation request suite: renderer_state_write=false"
