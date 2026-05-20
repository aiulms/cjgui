#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage126 mutation request dry-run suite packet，
# 生成 mutation request result envelope packet。它只固化 request rejection 与
# rollback eligibility，不执行 guarded state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE127_TMPDIR:-/tmp/cjgui-stage127-mr-result-packet-$$}"
UPSTREAM_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite.sh"
UPSTREAM_LOG="$TMP_DIR/upstream-mutation-request-suite.log"
RESULT_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-mutation-request-result-envelope-first-slice.packet"
UPSTREAM_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$UPSTREAM_SUITE_SCRIPT" ]]; then
  echo "cjgui mutation request result envelope packet: missing executable script $UPSTREAM_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$UPSTREAM_SUITE_SCRIPT"; then
  echo "cjgui mutation request result envelope packet: syntax check failed $UPSTREAM_SUITE_SCRIPT" >&2
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
    echo "cjgui mutation request result envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

upstream_packet_source="provided_stage126_mutation_request_suite_packet"
current_shell_upstream_rerun_ready="not_run"
if [[ -z "$UPSTREAM_SUITE_PACKET" ]]; then
  upstream_packet_source="current_shell_stage126_mutation_request_suite_rerun"
  if env TMPDIR="/tmp/cjgui-stage127-upstream-mr-suite-$$" zsh "$UPSTREAM_SUITE_SCRIPT" > "$UPSTREAM_LOG" 2>&1; then
    current_shell_upstream_rerun_ready="true"
    UPSTREAM_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui mutation request result envelope packet: upstream suite failed" >&2
    echo "cjgui mutation request result envelope packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$UPSTREAM_SUITE_PACKET" ]]; then
    echo "cjgui mutation request result envelope packet: provided suite packet missing $UPSTREAM_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_upstream_mutation_request_suite_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$UPSTREAM_SUITE_PACKET" || ! -f "$UPSTREAM_SUITE_PACKET" ]]; then
  echo "cjgui mutation request result envelope packet: missing upstream suite packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_suite_passed=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true" \
  "renderer_state_mutation_request_shape_defined=true" \
  "decision_denial_bound_to_mutation_request_rejection=true" \
  "mutation_request_non_executable=true" \
  "mutation_request_dry_run_only=true" \
  "renderer_state_mutation_request_rejected=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$UPSTREAM_SUITE_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$UPSTREAM_SUITE_PACKET" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_mutation_request_dry_run_suite_packet=$UPSTREAM_SUITE_PACKET"
  echo "upstream_mutation_request_suite_packet_source=$upstream_packet_source"
  echo "current_shell_upstream_mutation_request_rerun_ready=$current_shell_upstream_rerun_ready"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true"
  echo "renderer_state_mutation_request_result_envelope_materialized=true"
  echo "mutation_request_shape_persisted_as_dry_run_fact=true"
  echo "mutation_request_rejection_persisted_as_dry_run_fact=true"
  echo "rollback_eligibility_blocked=true"
  echo "guarded_state_write_executor_input_prepared=true"
  echo "mutation_request_result_envelope_non_mutating=true"
  echo "guarded_state_write_executor_non_executable=true"
  echo "frame_hash_value_persisted=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui mutation request result envelope packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet"
echo "cjgui mutation request result envelope packet: mutation_request_result_envelope_packet_path=$RESULT_PACKET"
echo "cjgui mutation request result envelope packet: semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true"
echo "cjgui mutation request result envelope packet: renderer_state_write=false"
