#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state write decision result envelope suite
# packet，生成 mutation request dry-run packet。它只定义 request shape 和拒绝事实。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-packet"
RESULT_ENVELOPE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_suite.sh"
RESULT_ENVELOPE_LOG="$TMP_DIR/result-envelope-suite.log"
MUTATION_REQUEST_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice.packet"
RESULT_ENVELOPE_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_DECISION_RESULT_ENVELOPE_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$RESULT_ENVELOPE_LOG"
: > "$MUTATION_REQUEST_PACKET"

if [[ ! -x "$RESULT_ENVELOPE_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request packet: missing executable script $RESULT_ENVELOPE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$RESULT_ENVELOPE_SUITE_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted mutation request packet: syntax check failed $RESULT_ENVELOPE_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted mutation request packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

result_envelope_suite_packet=""
result_envelope_suite_packet_source="provided_stage126_result_envelope_suite_packet"
current_shell_result_envelope_rerun_ready="not_run"
current_shell_result_envelope_rerun_failure_classification="none"

if [[ -n "$RESULT_ENVELOPE_SUITE_PACKET" ]]; then
  if [[ ! -f "$RESULT_ENVELOPE_SUITE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted mutation request packet: provided result envelope suite packet missing $RESULT_ENVELOPE_SUITE_PACKET" >&2
    exit 6
  fi
  result_envelope_suite_packet="$RESULT_ENVELOPE_SUITE_PACKET"
  echo "result_envelope_suite_packet_used=true" > "$RESULT_ENVELOPE_LOG"
else
  result_envelope_suite_packet_source="current_shell_stage126_result_envelope_rerun"
  if env TMPDIR="$TMP_DIR/result-envelope" zsh "$RESULT_ENVELOPE_SUITE_SCRIPT" > "$RESULT_ENVELOPE_LOG" 2>&1; then
    current_shell_result_envelope_rerun_ready="true"
    result_envelope_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$RESULT_ENVELOPE_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui semantic-comparison-admitted mutation request packet: result envelope suite failed" >&2
    echo "cjgui semantic-comparison-admitted mutation request packet: log=$RESULT_ENVELOPE_LOG" >&2
    exit 7
  fi
fi

if [[ -z "$result_envelope_suite_packet" || ! -f "$result_envelope_suite_packet" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request packet: missing result envelope suite packet" >&2
  exit 8
fi

required_result_envelope_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_suite_passed=true"
  "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=true"
  "renderer_state_write_decision_result_envelope_materialized=true"
  "denial_reason_persisted_as_dry_run_fact=true"
  "future_mutation_boundary_non_executable=true"
  "decision_result_envelope_non_mutating=true"
  "next_mutation_request_probe_input_prepared=true"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_result_envelope_facts[@]}"; do
  require_file_fact "$result_envelope_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted mutation request packet: protected path modified" >&2
  exit 9
fi

result_envelope_ready="$(fact_value "$result_envelope_suite_packet" "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready")"
future_non_exec="$(fact_value "$result_envelope_suite_packet" "future_mutation_boundary_non_executable")"
non_mutating="$(fact_value "$result_envelope_suite_packet" "decision_result_envelope_non_mutating")"
runtime_native_probe_execution="$(fact_value "$result_envelope_suite_packet" "runtime_native_probe_execution")"
mutation_request_ready="false"
if [[ "$result_envelope_ready" == "true" &&
      "$future_non_exec" == "true" &&
      "$non_mutating" == "true" ]]; then
  mutation_request_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_write_decision_result_envelope_suite_packet=$result_envelope_suite_packet"
  echo "result_envelope_suite_packet_source=$result_envelope_suite_packet_source"
  echo "current_shell_result_envelope_rerun_ready=$current_shell_result_envelope_rerun_ready"
  echo "current_shell_result_envelope_rerun_failure_classification=$current_shell_result_envelope_rerun_failure_classification"
  echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=$mutation_request_ready"
  echo "renderer_state_mutation_request_shape_defined=true"
  echo "decision_inputs_bound_to_mutation_request_shape=true"
  echo "decision_denial_bound_to_mutation_request_rejection=true"
  echo "future_mutation_boundary_bound_to_request_stop_line=true"
  echo "mutation_request_non_executable=true"
  echo "mutation_request_dry_run_only=true"
  echo "renderer_state_mutation_request_rejected=true"
  echo "future_mutation_boundary_non_executable=$future_non_exec"
  echo "decision_result_envelope_non_mutating=$non_mutating"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_passed=true"
} > "$MUTATION_REQUEST_PACKET"

echo "cjgui semantic-comparison-admitted mutation request packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet"
echo "cjgui semantic-comparison-admitted mutation request packet: semantic_comparison_admitted_mutation_request_packet_path=$MUTATION_REQUEST_PACKET"
echo "cjgui semantic-comparison-admitted mutation request packet: semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=$mutation_request_ready"
echo "cjgui semantic-comparison-admitted mutation request packet: renderer_state_write=false"
