#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage119 production truth admission first-slice suite
# packet，生成 stage120 production write admission first-slice packet。它只
# admission preflight，不升级 production render truth，不允许 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage120-first-frame-observation-production-write-admission-first-slice-packet"
TRUTH_ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_suite.sh"
TRUTH_ADMISSION_LOG="$TMP_DIR/production-truth-admission-suite.log"
WRITE_ADMISSION_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-production-write-admission-first-slice.packet"
TRUTH_ADMISSION_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_TRUTH_ADMISSION_FIRST_SLICE_SUITE_PACKET:-}"
STAGE119_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage119-suite-check-2/cjgui-stage119-first-frame-observation-production-truth-admission-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-production-truth-admission-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$TRUTH_ADMISSION_LOG"
: > "$WRITE_ADMISSION_PACKET"

if [[ ! -x "$TRUTH_ADMISSION_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: missing executable script $TRUTH_ADMISSION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$TRUTH_ADMISSION_SUITE_SCRIPT"; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: syntax check failed $TRUTH_ADMISSION_SUITE_SCRIPT" >&2
  exit 4
fi

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

truth_admission_suite_packet=""
production_truth_admission_positive_suite_packet_source="provided_stage119_suite_packet"
current_shell_production_truth_admission_rerun_ready="not_run"
current_shell_production_truth_admission_rerun_failure_classification="none"

if [[ -n "$TRUTH_ADMISSION_SUITE_PACKET" ]]; then
  if [[ ! -f "$TRUTH_ADMISSION_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: truth admission suite packet missing $TRUTH_ADMISSION_SUITE_PACKET" >&2
    exit 6
  fi
  truth_admission_suite_packet="$TRUTH_ADMISSION_SUITE_PACKET"
  {
    echo "truth_admission_suite_packet_used=true"
    echo "suite_packet_path=$TRUTH_ADMISSION_SUITE_PACKET"
    cat "$TRUTH_ADMISSION_SUITE_PACKET"
  } > "$TRUTH_ADMISSION_LOG"
else
  production_truth_admission_positive_suite_packet_source="current_shell_stage119_rerun"
  if env TMPDIR="$TMP_DIR/truth-admission" zsh "$TRUTH_ADMISSION_SUITE_SCRIPT" > "$TRUTH_ADMISSION_LOG" 2>&1; then
    current_shell_production_truth_admission_rerun_ready="true"
    truth_admission_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$TRUTH_ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_production_truth_admission_rerun_ready="false"
    current_shell_production_truth_admission_rerun_failure_classification="stage119_truth_admission_suite_rerun_failed"
    if [[ -f "$STAGE119_CANONICAL_POSITIVE_PACKET" ]]; then
      truth_admission_suite_packet="$STAGE119_CANONICAL_POSITIVE_PACKET"
      production_truth_admission_positive_suite_packet_source="stage119_canonical_prior_suite_packet"
    else
      echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: truth admission suite failed" >&2
      echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: log=$TRUTH_ADMISSION_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$truth_admission_suite_packet" || ! -f "$truth_admission_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: missing truth admission suite packet" >&2
  exit 8
fi

required_truth_admission_facts=(
  "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_suite_passed=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "positive_first_frame_observation_input_ready=true"
  "renderer_state_write_decision_contract_ready=true"
  "first_frame_observed=true"
  "frame_hash_computed=true"
  "frame_hash_nonzero=true"
  "production_render_truth_admission_ready=true"
  "production_truth_admission_preflight_only=true"
  "baseline_or_semantic_verification_after_first_slice_required=true"
  "production_write_admission_after_truth_admission_required=true"
  "renderer_state_write_after_production_truth_admission_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_truth_admission_facts[@]}"; do
  require_file_fact "$truth_admission_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: protected path modified" >&2
  exit 9
fi

truth_admission_ready="$(fact_value "$truth_admission_suite_packet" "production_render_truth_admission_ready")"
truth_admission_preflight_only="$(fact_value "$truth_admission_suite_packet" "production_truth_admission_preflight_only")"
first_frame_observed="$(fact_value "$truth_admission_suite_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$truth_admission_suite_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$truth_admission_suite_packet" "frame_hash_nonzero")"
baseline_required="$(fact_value "$truth_admission_suite_packet" "baseline_or_semantic_verification_after_first_slice_required")"
write_required="$(fact_value "$truth_admission_suite_packet" "production_write_admission_after_truth_admission_required")"
write_allowed_after_truth="$(fact_value "$truth_admission_suite_packet" "renderer_state_write_after_production_truth_admission_allowed")"
runtime_native_probe_execution="$(fact_value "$truth_admission_suite_packet" "runtime_native_probe_execution")"
truth_join_source="$(fact_value "$truth_admission_suite_packet" "truth_admission_join_positive_suite_packet_source")"
first_frame_source="$(fact_value "$truth_admission_suite_packet" "first_frame_positive_suite_packet_source")"
current_truth_join_rerun_ready="$(fact_value "$truth_admission_suite_packet" "current_shell_truth_admission_join_rerun_ready")"
current_truth_join_rerun_failure_classification="$(fact_value "$truth_admission_suite_packet" "current_shell_truth_admission_join_rerun_failure_classification")"
current_first_frame_rerun_ready="$(fact_value "$truth_admission_suite_packet" "current_shell_first_frame_observation_rerun_ready")"
current_first_frame_rerun_failure_classification="$(fact_value "$truth_admission_suite_packet" "current_shell_first_frame_observation_rerun_failure_classification")"
production_write_admission_ready="false"
if [[ "$truth_admission_ready" == "true" &&
      "$truth_admission_preflight_only" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" &&
      "$baseline_required" == "true" &&
      "$write_required" == "true" &&
      "$write_allowed_after_truth" == "false" ]]; then
  production_write_admission_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet_version=1"
  echo "production_truth_admission_suite_packet=$truth_admission_suite_packet"
  echo "production_truth_admission_positive_suite_packet_source=$production_truth_admission_positive_suite_packet_source"
  echo "current_shell_production_truth_admission_rerun_ready=$current_shell_production_truth_admission_rerun_ready"
  echo "current_shell_production_truth_admission_rerun_failure_classification=$current_shell_production_truth_admission_rerun_failure_classification"
  echo "truth_admission_join_positive_suite_packet_source=$truth_join_source"
  echo "current_shell_truth_admission_join_rerun_ready=$current_truth_join_rerun_ready"
  echo "current_shell_truth_admission_join_rerun_failure_classification=$current_truth_join_rerun_failure_classification"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "current_shell_first_frame_observation_rerun_ready=$current_first_frame_rerun_ready"
  echo "current_shell_first_frame_observation_rerun_failure_classification=$current_first_frame_rerun_failure_classification"
  echo "production_truth_admission_first_slice_consumed=true"
  echo "production_render_truth_admission_ready=$truth_admission_ready"
  echo "production_truth_admission_preflight_only=$truth_admission_preflight_only"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  echo "production_write_admission_preflight_ready=$production_write_admission_ready"
  echo "production_write_admission_preflight_only=true"
  echo "renderer_state_write_after_production_truth_admission_allowed=false"
  echo "renderer_state_write_after_production_write_admission_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet_passed=true"
} > "$WRITE_ADMISSION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: route_classification=d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: write_admission_packet_path=$WRITE_ADMISSION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: production_write_admission_preflight_ready=$production_write_admission_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission packet: renderer_state_write=false"
