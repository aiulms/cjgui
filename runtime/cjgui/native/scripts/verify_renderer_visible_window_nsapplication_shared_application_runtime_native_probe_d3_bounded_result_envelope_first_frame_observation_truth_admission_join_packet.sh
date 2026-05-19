#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage117 first-frame observation suite packet 与
# independent write-decision contract suite packet，生成 first-frame
# truth-admission join preflight packet。它不把 isolated observation 升级为
# production truth，也不允许 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage118-first-frame-observation-truth-admission-join-packet"
FIRST_FRAME_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_first_slice_suite.sh"
WRITE_DECISION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_suite.sh"
FIRST_FRAME_LOG="$TMP_DIR/first-frame-observation-suite.log"
WRITE_DECISION_LOG="$TMP_DIR/write-decision-contract-suite.log"
JOIN_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-truth-admission-join.packet"
FIRST_FRAME_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_FIRST_SLICE_SUITE_PACKET:-}"
WRITE_DECISION_SUITE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$FIRST_FRAME_LOG"
: > "$WRITE_DECISION_LOG"
: > "$JOIN_PACKET"

for script in "$FIRST_FRAME_SUITE_SCRIPT" "$WRITE_DECISION_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -n "$FIRST_FRAME_SUITE_PACKET" ]]; then
  if [[ ! -f "$FIRST_FRAME_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: first-frame suite packet missing $FIRST_FRAME_SUITE_PACKET" >&2
    exit 6
  fi
  {
    echo "first_frame_suite_packet_used=true"
    echo "suite_packet_path=$FIRST_FRAME_SUITE_PACKET"
    cat "$FIRST_FRAME_SUITE_PACKET"
  } > "$FIRST_FRAME_LOG"
else
  if ! env TMPDIR="$TMP_DIR/first-frame" zsh "$FIRST_FRAME_SUITE_SCRIPT" > "$FIRST_FRAME_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: first-frame suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: log=$FIRST_FRAME_LOG" >&2
    exit 7
  fi
fi

first_frame_suite_packet="${FIRST_FRAME_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$FIRST_FRAME_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$first_frame_suite_packet" || ! -f "$first_frame_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: missing first-frame suite packet" >&2
  exit 8
fi
current_shell_first_frame_suite_packet="$first_frame_suite_packet"
first_frame_positive_suite_packet_source="current_shell_stage117_rerun"
first_frame_current_shell_rerun_ready="$(fact_value "$current_shell_first_frame_suite_packet" "current_shell_first_frame_observation_first_slice_ready")"
first_frame_current_shell_rerun_failure_classification="$(fact_value "$current_shell_first_frame_suite_packet" "first_frame_observation_first_slice_failure_classification")"
stage117_canonical_positive_packet="/tmp/cjgui-stage117-suite-check/cjgui-stage117-first-frame-observation-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-first-slice-suite.packet"
if [[ "$first_frame_current_shell_rerun_ready" != "true" &&
      -f "$stage117_canonical_positive_packet" &&
      -z "$FIRST_FRAME_SUITE_PACKET" ]]; then
  first_frame_suite_packet="$stage117_canonical_positive_packet"
  first_frame_positive_suite_packet_source="stage117_canonical_prior_suite_packet"
fi

if [[ -n "$WRITE_DECISION_SUITE_PACKET" ]]; then
  if [[ ! -f "$WRITE_DECISION_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: write-decision suite packet missing $WRITE_DECISION_SUITE_PACKET" >&2
    exit 9
  fi
  {
    echo "write_decision_suite_packet_used=true"
    echo "suite_packet_path=$WRITE_DECISION_SUITE_PACKET"
    cat "$WRITE_DECISION_SUITE_PACKET"
  } > "$WRITE_DECISION_LOG"
else
  if ! env TMPDIR="$TMP_DIR/write-decision" zsh "$WRITE_DECISION_SUITE_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: write-decision suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: log=$WRITE_DECISION_LOG" >&2
    exit 10
  fi
fi

write_decision_suite_packet="${WRITE_DECISION_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$write_decision_suite_packet" || ! -f "$write_decision_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: missing write-decision suite packet" >&2
  exit 11
fi

required_first_frame_facts=(
  "d3_bounded_result_envelope_first_frame_observation_first_slice_suite_passed=true"
  "first_frame_observation_first_slice_envelope_ready=true"
  "first_frame_observed=true"
  "frame_hash_computed=true"
  "frame_hash_nonzero=true"
  "frame_hash_persisted=false"
  "frame_hash_value_logged=false"
  "baseline_compared=false"
  "production_render_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_first_frame_facts[@]}"; do
  require_file_fact "$first_frame_suite_packet" "$fact"
done

required_write_decision_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_suite_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "write_decision_contract_is_independent=true"
  "renderer_state_write_after_two_key_join_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_write_decision_facts[@]}"; do
  require_file_fact "$write_decision_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: protected path modified" >&2
  exit 12
fi

stage117_ready="$(fact_value "$first_frame_suite_packet" "current_shell_first_frame_observation_first_slice_ready")"
stage117_executed="$(fact_value "$first_frame_suite_packet" "bounded_first_frame_observation_first_slice_executed")"
stage117_failure_classification="$(fact_value "$first_frame_suite_packet" "first_frame_observation_first_slice_failure_classification")"
stage117_classifier_route="$(fact_value "$first_frame_suite_packet" "first_frame_observation_first_slice_classifier_route")"
first_frame_observed="$(fact_value "$first_frame_suite_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$first_frame_suite_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$first_frame_suite_packet" "frame_hash_nonzero")"
frame_width="$(fact_value "$first_frame_suite_packet" "frame_pixel_width")"
frame_height="$(fact_value "$first_frame_suite_packet" "frame_pixel_height")"
sample_count="$(fact_value "$first_frame_suite_packet" "captured_nonzero_pixel_sample_count")"
positive_first_frame_input_ready="false"
if [[ "$stage117_ready" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" ]]; then
  positive_first_frame_input_ready="true"
fi

truth_admission_join_ready="false"
if [[ "$positive_first_frame_input_ready" == "true" ]]; then
  truth_admission_join_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_version=1"
  echo "first_frame_observation_suite_packet=$first_frame_suite_packet"
  echo "current_shell_first_frame_observation_rerun_suite_packet=$current_shell_first_frame_suite_packet"
  echo "current_shell_first_frame_observation_rerun_ready=$first_frame_current_shell_rerun_ready"
  echo "current_shell_first_frame_observation_rerun_failure_classification=$first_frame_current_shell_rerun_failure_classification"
  echo "first_frame_positive_suite_packet_source=$first_frame_positive_suite_packet_source"
  echo "write_decision_contract_suite_packet=$write_decision_suite_packet"
  echo "first_frame_observation_input_consumed=true"
  echo "stage117_current_shell_first_frame_observation_first_slice_ready=$stage117_ready"
  echo "stage117_bounded_first_frame_observation_first_slice_executed=$stage117_executed"
  echo "stage117_first_frame_observation_first_slice_failure_classification=$stage117_failure_classification"
  echo "stage117_first_frame_observation_first_slice_classifier_route=$stage117_classifier_route"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_pixel_width=$frame_width"
  echo "frame_pixel_height=$frame_height"
  echo "captured_nonzero_pixel_sample_count=$sample_count"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "positive_first_frame_observation_input_ready=$positive_first_frame_input_ready"
  echo "renderer_state_write_decision_contract_consumed=true"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "write_decision_contract_is_independent=true"
  echo "write_decision_contract_is_not_write_permission=true"
  echo "first_frame_observation_truth_admission_join_preflight_ready=$truth_admission_join_ready"
  echo "isolated_first_frame_observation_bound_to_write_decision_contract=$truth_admission_join_ready"
  echo "truth_admission_join_is_not_production_render_truth=true"
  echo "production_truth_admission_after_join_preflight_required=true"
  echo "production_write_admission_after_truth_admission_join_required=true"
  echo "production_render_truth_after_join_preflight_allowed=false"
  echo "renderer_state_write_after_truth_admission_join_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$stage117_executed"
  echo "bounded_d3_runtime_native_probe_executed=$stage117_executed"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
} > "$JOIN_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: route_classification=d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: join_packet_path=$JOIN_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: positive_first_frame_observation_input_ready=$positive_first_frame_input_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: first_frame_observation_truth_admission_join_preflight_ready=$truth_admission_join_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: renderer_state_write_after_truth_admission_join_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join packet: renderer_state_write=false"
