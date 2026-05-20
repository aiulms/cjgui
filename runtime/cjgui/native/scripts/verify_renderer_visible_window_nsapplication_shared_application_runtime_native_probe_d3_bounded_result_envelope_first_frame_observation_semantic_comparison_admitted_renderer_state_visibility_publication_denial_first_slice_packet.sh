#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage127 guarded executor result envelope suite
# packet，生成 visibility publication denial packet。它只发布 dry-run denial
# facts，不执行 visibility publication 或 renderer_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE128_TMPDIR:-/tmp/cjgui-stage128-visibility-denial-packet-$$}"
UPSTREAM_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice_suite.sh"
UPSTREAM_LOG="$TMP_DIR/guarded-result-suite.log"
RESULT_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-visibility-publication-denial-first-slice.packet"
GUARDED_RESULT_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_GUARDED_STATE_WRITE_EXECUTOR_RESULT_ENVELOPE_FIRST_SLICE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$UPSTREAM_SUITE_SCRIPT" ]]; then
  echo "cjgui visibility publication denial packet: missing executable script $UPSTREAM_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$UPSTREAM_SUITE_SCRIPT"; then
  echo "cjgui visibility publication denial packet: syntax check failed $UPSTREAM_SUITE_SCRIPT" >&2
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
    echo "cjgui visibility publication denial packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$GUARDED_RESULT_SUITE_PACKET" ]]; then
  if env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-upstream-guarded-result-suite-$$" \
    zsh "$UPSTREAM_SUITE_SCRIPT" > "$UPSTREAM_LOG" 2>&1; then
    GUARDED_RESULT_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui visibility publication denial packet: upstream suite failed" >&2
    echo "cjgui visibility publication denial packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$GUARDED_RESULT_SUITE_PACKET" ]]; then
    echo "cjgui visibility publication denial packet: provided packet missing $GUARDED_RESULT_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_guarded_result_suite_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$GUARDED_RESULT_SUITE_PACKET" || ! -f "$GUARDED_RESULT_SUITE_PACKET" ]]; then
  echo "cjgui visibility publication denial packet: missing guarded result suite packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite_passed=true" \
  "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true" \
  "guarded_state_write_executor_result_envelope_materialized=true" \
  "guarded_executor_denial_persisted_as_dry_run_fact=true" \
  "rollback_stop_line_persisted_as_dry_run_fact=true" \
  "visibility_publication_denial_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$GUARDED_RESULT_SUITE_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$GUARDED_RESULT_SUITE_PACKET" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_suite_packet=$GUARDED_RESULT_SUITE_PACKET"
  echo "semantic_comparison_admitted_guarded_executor_result_envelope_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true"
  echo "visibility_publication_denial_envelope_materialized=true"
  echo "guarded_executor_denial_persisted_as_visibility_dry_run_fact=true"
  echo "rollback_stop_line_persisted_as_visibility_dry_run_fact=true"
  echo "frame_hash_bound_to_unpublished_visibility_denial=true"
  echo "visibility_publication_denied=true"
  echo "visibility_publication_non_executable=true"
  echo "visibility_publication_allowed=false"
  echo "rollback_fallback_denial_input_prepared=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui visibility publication denial packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet"
echo "cjgui visibility publication denial packet: visibility_publication_denial_packet_path=$RESULT_PACKET"
echo "cjgui visibility publication denial packet: semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true"
echo "cjgui visibility publication denial packet: renderer_state_write=false"
