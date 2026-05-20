#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state write decision dry-run suite packet，
# 生成 decision result envelope packet。结果 envelope 只承载 dry-run facts。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-write-decision-result-envelope-first-slice-packet"
WRITE_DECISION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_suite.sh"
WRITE_DECISION_LOG="$TMP_DIR/write-decision-suite.log"
RESULT_ENVELOPE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-decision-result-envelope-first-slice.packet"
WRITE_DECISION_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_DECISION_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$WRITE_DECISION_LOG"
: > "$RESULT_ENVELOPE_PACKET"

if [[ ! -x "$WRITE_DECISION_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write decision result envelope packet: missing executable script $WRITE_DECISION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$WRITE_DECISION_SUITE_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write decision result envelope packet: syntax check failed $WRITE_DECISION_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted write decision result envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

write_decision_suite_packet=""
write_decision_suite_packet_source="provided_stage126_write_decision_suite_packet"
current_shell_write_decision_rerun_ready="not_run"
current_shell_write_decision_rerun_failure_classification="none"

if [[ -n "$WRITE_DECISION_SUITE_PACKET" ]]; then
  if [[ ! -f "$WRITE_DECISION_SUITE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write decision result envelope packet: provided suite packet missing $WRITE_DECISION_SUITE_PACKET" >&2
    exit 6
  fi
  write_decision_suite_packet="$WRITE_DECISION_SUITE_PACKET"
  echo "write_decision_suite_packet_used=true" > "$WRITE_DECISION_LOG"
else
  write_decision_suite_packet_source="current_shell_stage126_write_decision_rerun"
  if env TMPDIR="$TMP_DIR/write-decision" zsh "$WRITE_DECISION_SUITE_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
    current_shell_write_decision_rerun_ready="true"
    write_decision_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui semantic-comparison-admitted write decision result envelope packet: write decision suite failed" >&2
    echo "cjgui semantic-comparison-admitted write decision result envelope packet: log=$WRITE_DECISION_LOG" >&2
    exit 7
  fi
fi

if [[ -z "$write_decision_suite_packet" || ! -f "$write_decision_suite_packet" ]]; then
  echo "cjgui semantic-comparison-admitted write decision result envelope packet: missing write decision suite packet" >&2
  exit 8
fi

required_write_decision_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_suite_passed=true"
  "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=true"
  "renderer_state_write_decision_dry_run_only=true"
  "renderer_state_write_decision_input_fields_defined=true"
  "renderer_state_write_denial_reasons_defined=true"
  "future_mutation_boundary_defined=true"
  "renderer_state_write_decision_denied=true"
  "renderer_state_write_after_decision_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_write_decision_facts[@]}"; do
  require_file_fact "$write_decision_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted write decision result envelope packet: protected path modified" >&2
  exit 9
fi

write_decision_ready="$(fact_value "$write_decision_suite_packet" "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready")"
decision_denied="$(fact_value "$write_decision_suite_packet" "renderer_state_write_decision_denied")"
future_boundary="$(fact_value "$write_decision_suite_packet" "future_mutation_boundary_defined")"
runtime_native_probe_execution="$(fact_value "$write_decision_suite_packet" "runtime_native_probe_execution")"
result_envelope_ready="false"
if [[ "$write_decision_ready" == "true" &&
      "$decision_denied" == "true" &&
      "$future_boundary" == "true" ]]; then
  result_envelope_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_write_decision_suite_packet=$write_decision_suite_packet"
  echo "write_decision_suite_packet_source=$write_decision_suite_packet_source"
  echo "current_shell_write_decision_rerun_ready=$current_shell_write_decision_rerun_ready"
  echo "current_shell_write_decision_rerun_failure_classification=$current_shell_write_decision_rerun_failure_classification"
  echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=$write_decision_ready"
  echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=$result_envelope_ready"
  echo "renderer_state_write_decision_result_envelope_materialized=true"
  echo "decision_inputs_persisted_as_dry_run_facts=true"
  echo "denial_reason_persisted_as_dry_run_fact=true"
  echo "future_mutation_boundary_persisted_as_dry_run_fact=true"
  echo "future_mutation_boundary_non_executable=true"
  echo "decision_result_envelope_non_mutating=true"
  echo "renderer_state_write_decision_denied=$decision_denied"
  echo "next_mutation_request_probe_input_prepared=true"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_packet_passed=true"
} > "$RESULT_ENVELOPE_PACKET"

echo "cjgui semantic-comparison-admitted write decision result envelope packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_packet"
echo "cjgui semantic-comparison-admitted write decision result envelope packet: semantic_comparison_admitted_write_decision_result_envelope_packet_path=$RESULT_ENVELOPE_PACKET"
echo "cjgui semantic-comparison-admitted write decision result envelope packet: semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=$result_envelope_ready"
echo "cjgui semantic-comparison-admitted write decision result envelope packet: renderer_state_write=false"
