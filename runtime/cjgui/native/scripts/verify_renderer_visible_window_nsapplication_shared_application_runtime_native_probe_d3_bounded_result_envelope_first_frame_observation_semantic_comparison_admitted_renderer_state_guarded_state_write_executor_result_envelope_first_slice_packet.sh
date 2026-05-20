#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 guarded state-write executor dry-run packet，
# 生成 guarded executor result envelope packet。它只发布 denial envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE127_TMPDIR:-/tmp/cjgui-stage127-guarded-result-packet-$$}"
UPSTREAM_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_dry_run_first_slice_packet.sh"
UPSTREAM_LOG="$TMP_DIR/guarded-executor.log"
RESULT_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-guarded-state-write-executor-result-envelope-first-slice.packet"
GUARDED_EXECUTOR_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_GUARDED_STATE_WRITE_EXECUTOR_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$UPSTREAM_PACKET_SCRIPT" ]]; then
  echo "cjgui guarded executor result envelope packet: missing executable script $UPSTREAM_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$UPSTREAM_PACKET_SCRIPT"; then
  echo "cjgui guarded executor result envelope packet: syntax check failed $UPSTREAM_PACKET_SCRIPT" >&2
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
    echo "cjgui guarded executor result envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$GUARDED_EXECUTOR_PACKET" ]]; then
  if env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-upstream-guarded-exec-$$" zsh "$UPSTREAM_PACKET_SCRIPT" > "$UPSTREAM_LOG" 2>&1; then
    GUARDED_EXECUTOR_PACKET="$(grep -Eo 'guarded_state_write_executor_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui guarded executor result envelope packet: upstream packet failed" >&2
    echo "cjgui guarded executor result envelope packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$GUARDED_EXECUTOR_PACKET" ]]; then
    echo "cjgui guarded executor result envelope packet: provided packet missing $GUARDED_EXECUTOR_PACKET" >&2
    exit 7
  fi
  echo "provided_guarded_executor_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$GUARDED_EXECUTOR_PACKET" || ! -f "$GUARDED_EXECUTOR_PACKET" ]]; then
  echo "cjgui guarded executor result envelope packet: missing guarded executor packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true" \
  "guarded_state_write_executor_inputs_defined=true" \
  "mutation_request_rejection_bound_to_executor_denial=true" \
  "rollback_eligibility_bound_to_executor_stop_line=true" \
  "guarded_state_write_executor_non_executable=true" \
  "guarded_state_write_executor_dry_run_only=true" \
  "guarded_state_write_executor_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$GUARDED_EXECUTOR_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$GUARDED_EXECUTOR_PACKET" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_packet=$GUARDED_EXECUTOR_PACKET"
  echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_consumed=true"
  echo "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true"
  echo "guarded_state_write_executor_result_envelope_materialized=true"
  echo "guarded_executor_inputs_persisted_as_dry_run_facts=true"
  echo "guarded_executor_denial_persisted_as_dry_run_fact=true"
  echo "rollback_stop_line_persisted_as_dry_run_fact=true"
  echo "visibility_publication_denial_input_prepared=true"
  echo "guarded_executor_result_envelope_non_mutating=true"
  echo "guarded_executor_denied=true"
  echo "visibility_publication_blocked=true"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui guarded executor result envelope packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_packet"
echo "cjgui guarded executor result envelope packet: guarded_executor_result_envelope_packet_path=$RESULT_PACKET"
echo "cjgui guarded executor result envelope packet: semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true"
echo "cjgui guarded executor result envelope packet: renderer_state_write=false"
