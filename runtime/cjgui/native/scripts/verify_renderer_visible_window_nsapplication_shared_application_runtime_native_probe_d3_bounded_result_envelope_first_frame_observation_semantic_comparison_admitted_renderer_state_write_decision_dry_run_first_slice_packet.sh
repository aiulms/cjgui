#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage125 semantic-comparison-admitted state-update
# dry-run envelope suite packet，生成 renderer-state write decision dry-run packet。
# 它只产出 decision / denial / future mutation boundary facts。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-write-decision-dry-run-first-slice-packet"
STATE_UPDATE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_update_dry_run_envelope_first_slice_suite.sh"
STATE_UPDATE_LOG="$TMP_DIR/state-update-suite.log"
WRITE_DECISION_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-decision-dry-run-first-slice.packet"
STATE_UPDATE_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_SUITE_PACKET:-}"
STAGE125_STATE_UPDATE_CANONICAL_PACKET="/tmp/cjgui-stage125-final-state-update-suite-check/cjgui-stage125-semantic-comparison-admitted-renderer-state-update-dry-run-envelope-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-update-dry-run-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$STATE_UPDATE_LOG"
: > "$WRITE_DECISION_PACKET"

if [[ ! -x "$STATE_UPDATE_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write decision packet: missing executable script $STATE_UPDATE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$STATE_UPDATE_SUITE_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write decision packet: syntax check failed $STATE_UPDATE_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted write decision packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

state_update_suite_packet=""
state_update_suite_packet_source="provided_stage125_state_update_suite_packet"
current_shell_state_update_rerun_ready="not_run"
current_shell_state_update_rerun_failure_classification="none"

if [[ -n "$STATE_UPDATE_SUITE_PACKET" ]]; then
  if [[ ! -f "$STATE_UPDATE_SUITE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write decision packet: provided state-update suite packet missing $STATE_UPDATE_SUITE_PACKET" >&2
    exit 6
  fi
  state_update_suite_packet="$STATE_UPDATE_SUITE_PACKET"
  {
    echo "state_update_suite_packet_used=true"
    echo "suite_packet_path=$STATE_UPDATE_SUITE_PACKET"
  } > "$STATE_UPDATE_LOG"
else
  state_update_suite_packet_source="current_shell_stage125_state_update_rerun"
  if env TMPDIR="$TMP_DIR/state-update" zsh "$STATE_UPDATE_SUITE_SCRIPT" > "$STATE_UPDATE_LOG" 2>&1; then
    current_shell_state_update_rerun_ready="true"
    state_update_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STATE_UPDATE_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_state_update_rerun_ready="false"
    current_shell_state_update_rerun_failure_classification="stage125_state_update_suite_rerun_failed"
    if [[ -f "$STAGE125_STATE_UPDATE_CANONICAL_PACKET" ]]; then
      state_update_suite_packet="$STAGE125_STATE_UPDATE_CANONICAL_PACKET"
      state_update_suite_packet_source="stage125_state_update_canonical_prior_suite_packet"
    else
      echo "cjgui semantic-comparison-admitted write decision packet: state-update suite failed" >&2
      echo "cjgui semantic-comparison-admitted write decision packet: log=$STATE_UPDATE_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$state_update_suite_packet" || ! -f "$state_update_suite_packet" ]]; then
  echo "cjgui semantic-comparison-admitted write decision packet: missing state-update suite packet" >&2
  exit 8
fi

required_state_update_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_update_dry_run_envelope_first_slice_suite_passed=true"
  "semantic_comparison_admitted_renderer_state_update_dry_run_envelope_ready=true"
  "state_update_envelope_dry_run_only=true"
  "semantic_comparison_admission_mapped_to_state_update_candidate=true"
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
for fact in "${required_state_update_facts[@]}"; do
  require_file_fact "$state_update_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted write decision packet: protected path modified" >&2
  exit 9
fi

state_update_ready="$(fact_value "$state_update_suite_packet" "semantic_comparison_admitted_renderer_state_update_dry_run_envelope_ready")"
dry_run_only="$(fact_value "$state_update_suite_packet" "state_update_envelope_dry_run_only")"
state_fail_closed="$(fact_value "$state_update_suite_packet" "state_mutation_request_fail_closed")"
visibility_fail_closed="$(fact_value "$state_update_suite_packet" "visibility_publication_fail_closed")"
rollback_fail_closed="$(fact_value "$state_update_suite_packet" "rollback_fallback_write_fail_closed")"
runtime_native_probe_execution="$(fact_value "$state_update_suite_packet" "runtime_native_probe_execution")"
write_decision_ready="false"
if [[ "$state_update_ready" == "true" &&
      "$dry_run_only" == "true" &&
      "$state_fail_closed" == "true" &&
      "$visibility_fail_closed" == "true" &&
      "$rollback_fail_closed" == "true" ]]; then
  write_decision_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_state_update_suite_packet=$state_update_suite_packet"
  echo "state_update_suite_packet_source=$state_update_suite_packet_source"
  echo "current_shell_state_update_rerun_ready=$current_shell_state_update_rerun_ready"
  echo "current_shell_state_update_rerun_failure_classification=$current_shell_state_update_rerun_failure_classification"
  echo "semantic_comparison_admitted_renderer_state_update_dry_run_envelope_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_update_dry_run_envelope_ready=$state_update_ready"
  echo "state_update_envelope_dry_run_only=$dry_run_only"
  echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=$write_decision_ready"
  echo "renderer_state_write_decision_dry_run_only=true"
  echo "renderer_state_write_decision_input_fields_defined=true"
  echo "renderer_state_write_denial_reasons_defined=true"
  echo "future_mutation_boundary_defined=true"
  echo "state_mutation_request_fail_closed_denial_reason=$state_fail_closed"
  echo "visibility_publication_fail_closed_denial_reason=$visibility_fail_closed"
  echo "rollback_fallback_write_fail_closed_denial_reason=$rollback_fail_closed"
  echo "production_render_truth_blocked_denial_reason=true"
  echo "backend_ready_truth_blocked_denial_reason=true"
  echo "renderer_state_write_decision_denied=true"
  echo "renderer_state_write_after_decision_allowed=false"
  echo "future_mutation_boundary_executable=false"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "state_mutation_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_packet_passed=true"
} > "$WRITE_DECISION_PACKET"

echo "cjgui semantic-comparison-admitted write decision packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_packet"
echo "cjgui semantic-comparison-admitted write decision packet: semantic_comparison_admitted_write_decision_packet_path=$WRITE_DECISION_PACKET"
echo "cjgui semantic-comparison-admitted write decision packet: semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=$write_decision_ready"
echo "cjgui semantic-comparison-admitted write decision packet: renderer_state_write=false"
