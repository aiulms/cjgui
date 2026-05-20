#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 mutation request result envelope packet，
# 生成 guarded state-write executor dry-run packet。它只定义 executor denial。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE127_TMPDIR:-/tmp/cjgui-stage127-guarded-exec-packet-$$}"
UPSTREAM_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet.sh"
UPSTREAM_LOG="$TMP_DIR/mutation-request-result-envelope.log"
EXECUTOR_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-guarded-state-write-executor-dry-run-first-slice.packet"
MUTATION_REQUEST_RESULT_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_RESULT_ENVELOPE_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$EXECUTOR_PACKET"

if [[ ! -x "$UPSTREAM_PACKET_SCRIPT" ]]; then
  echo "cjgui guarded state-write executor packet: missing executable script $UPSTREAM_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$UPSTREAM_PACKET_SCRIPT"; then
  echo "cjgui guarded state-write executor packet: syntax check failed $UPSTREAM_PACKET_SCRIPT" >&2
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
    echo "cjgui guarded state-write executor packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$MUTATION_REQUEST_RESULT_PACKET" ]]; then
  if env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-upstream-mr-result-$$" zsh "$UPSTREAM_PACKET_SCRIPT" > "$UPSTREAM_LOG" 2>&1; then
    MUTATION_REQUEST_RESULT_PACKET="$(grep -Eo 'mutation_request_result_envelope_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui guarded state-write executor packet: upstream packet failed" >&2
    echo "cjgui guarded state-write executor packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$MUTATION_REQUEST_RESULT_PACKET" ]]; then
    echo "cjgui guarded state-write executor packet: provided packet missing $MUTATION_REQUEST_RESULT_PACKET" >&2
    exit 7
  fi
  echo "provided_mutation_request_result_envelope_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$MUTATION_REQUEST_RESULT_PACKET" || ! -f "$MUTATION_REQUEST_RESULT_PACKET" ]]; then
  echo "cjgui guarded state-write executor packet: missing mutation request result envelope packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true" \
  "renderer_state_mutation_request_result_envelope_materialized=true" \
  "mutation_request_rejection_persisted_as_dry_run_fact=true" \
  "rollback_eligibility_blocked=true" \
  "guarded_state_write_executor_input_prepared=true" \
  "mutation_request_result_envelope_non_mutating=true" \
  "guarded_state_write_executor_non_executable=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$MUTATION_REQUEST_RESULT_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$MUTATION_REQUEST_RESULT_PACKET" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_mutation_request_result_envelope_packet=$MUTATION_REQUEST_RESULT_PACKET"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_consumed=true"
  echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true"
  echo "guarded_state_write_executor_inputs_defined=true"
  echo "mutation_request_rejection_bound_to_executor_denial=true"
  echo "rollback_eligibility_bound_to_executor_stop_line=true"
  echo "guarded_state_write_executor_non_executable=true"
  echo "guarded_state_write_executor_dry_run_only=true"
  echo "guarded_state_write_executor_denied=true"
  echo "executor_result_envelope_pending=true"
  echo "mutation_request_result_envelope_non_mutating=true"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "frame_hash_value_persisted=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_packet_passed=true"
} > "$EXECUTOR_PACKET"

echo "cjgui guarded state-write executor packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_packet"
echo "cjgui guarded state-write executor packet: guarded_state_write_executor_packet_path=$EXECUTOR_PACKET"
echo "cjgui guarded state-write executor packet: semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true"
echo "cjgui guarded state-write executor packet: renderer_state_write=false"
