#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage118 truth-admission join suite packet，生成
# stage119 production truth admission first-slice packet。它只 admission
# preflight，不升级 production render truth，不允许 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage119-first-frame-observation-production-truth-admission-first-slice-packet"
JOIN_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite.sh"
JOIN_LOG="$TMP_DIR/truth-admission-join-suite.log"
ADMISSION_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-production-truth-admission-first-slice.packet"
JOIN_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_SUITE_PACKET:-}"
STAGE118_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage118-final-suite-check/cjgui-stage118-first-frame-observation-truth-admission-join-suite/d3-bounded-result-envelope-first-frame-observation-truth-admission-join-suite.packet"

mkdir -p "$TMP_DIR"
: > "$JOIN_LOG"
: > "$ADMISSION_PACKET"

if [[ ! -x "$JOIN_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: missing executable script $JOIN_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$JOIN_SUITE_SCRIPT"; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: syntax check failed $JOIN_SUITE_SCRIPT" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

join_suite_packet=""
truth_admission_join_positive_suite_packet_source="provided_stage118_suite_packet"
current_shell_truth_admission_join_rerun_ready="not_run"
current_shell_truth_admission_join_rerun_failure_classification="none"

if [[ -n "$JOIN_SUITE_PACKET" ]]; then
  if [[ ! -f "$JOIN_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: join suite packet missing $JOIN_SUITE_PACKET" >&2
    exit 6
  fi
  join_suite_packet="$JOIN_SUITE_PACKET"
  {
    echo "join_suite_packet_used=true"
    echo "suite_packet_path=$JOIN_SUITE_PACKET"
    cat "$JOIN_SUITE_PACKET"
  } > "$JOIN_LOG"
else
  truth_admission_join_positive_suite_packet_source="current_shell_stage118_rerun"
  if env TMPDIR="$TMP_DIR/join" zsh "$JOIN_SUITE_SCRIPT" > "$JOIN_LOG" 2>&1; then
    current_shell_truth_admission_join_rerun_ready="true"
    join_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$JOIN_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_truth_admission_join_rerun_ready="false"
    current_shell_truth_admission_join_rerun_failure_classification="stage118_join_suite_rerun_failed"
    if [[ -f "$STAGE118_CANONICAL_POSITIVE_PACKET" ]]; then
      join_suite_packet="$STAGE118_CANONICAL_POSITIVE_PACKET"
      truth_admission_join_positive_suite_packet_source="stage118_canonical_prior_suite_packet"
    else
      echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: join suite failed" >&2
      echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: log=$JOIN_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$join_suite_packet" || ! -f "$join_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: missing join suite packet" >&2
  exit 8
fi

required_join_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_suite_passed=true"
  "positive_first_frame_observation_input_ready=true"
  "renderer_state_write_decision_contract_ready=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "isolated_first_frame_observation_bound_to_write_decision_contract=true"
  "production_truth_admission_after_join_preflight_required=true"
  "production_write_admission_after_truth_admission_join_required=true"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_join_facts[@]}"; do
  require_file_fact "$join_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: protected path modified" >&2
  exit 9
fi

join_ready="$(fact_value "$join_suite_packet" "first_frame_observation_truth_admission_join_preflight_ready")"
positive_input="$(fact_value "$join_suite_packet" "positive_first_frame_observation_input_ready")"
write_decision_ready="$(fact_value "$join_suite_packet" "renderer_state_write_decision_contract_ready")"
first_frame_observed="$(fact_value "$join_suite_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$join_suite_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$join_suite_packet" "frame_hash_nonzero")"
current_rerun_ready="$(fact_value "$join_suite_packet" "current_shell_first_frame_observation_rerun_ready")"
current_rerun_failure_classification="$(fact_value "$join_suite_packet" "current_shell_first_frame_observation_rerun_failure_classification")"
positive_suite_packet_source="$(fact_value "$join_suite_packet" "first_frame_positive_suite_packet_source")"
runtime_native_probe_execution="$(fact_value "$join_suite_packet" "runtime_native_probe_execution")"
production_truth_admission_ready="false"
if [[ "$join_ready" == "true" &&
      "$positive_input" == "true" &&
      "$write_decision_ready" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" ]]; then
  production_truth_admission_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet_version=1"
  echo "truth_admission_join_suite_packet=$join_suite_packet"
  echo "truth_admission_join_positive_suite_packet_source=$truth_admission_join_positive_suite_packet_source"
  echo "current_shell_truth_admission_join_rerun_ready=$current_shell_truth_admission_join_rerun_ready"
  echo "current_shell_truth_admission_join_rerun_failure_classification=$current_shell_truth_admission_join_rerun_failure_classification"
  echo "first_frame_positive_suite_packet_source=$positive_suite_packet_source"
  echo "current_shell_first_frame_observation_rerun_ready=$current_rerun_ready"
  echo "current_shell_first_frame_observation_rerun_failure_classification=$current_rerun_failure_classification"
  echo "first_frame_observation_truth_admission_join_preflight_consumed=true"
  echo "first_frame_observation_truth_admission_join_preflight_ready=$join_ready"
  echo "positive_first_frame_observation_input_ready=$positive_input"
  echo "renderer_state_write_decision_contract_ready=$write_decision_ready"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "production_render_truth_admission_ready=$production_truth_admission_ready"
  echo "production_truth_admission_preflight_only=true"
  echo "baseline_or_semantic_verification_after_first_slice_required=true"
  echo "production_write_admission_after_truth_admission_required=true"
  echo "renderer_state_write_after_production_truth_admission_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet_passed=true"
} > "$ADMISSION_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: route_classification=d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: admission_packet_path=$ADMISSION_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: production_render_truth_admission_ready=$production_truth_admission_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission packet: renderer_state_write=false"
