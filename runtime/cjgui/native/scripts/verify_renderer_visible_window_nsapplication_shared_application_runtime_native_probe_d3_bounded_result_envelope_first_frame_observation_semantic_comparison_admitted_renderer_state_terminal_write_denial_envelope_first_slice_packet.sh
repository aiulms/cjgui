#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 rollback fallback denial envelope packet，生成
# terminal renderer-state write denial envelope packet。该 packet 是本阶段的
# 最终 dry-run envelope，不做 production truth 或 renderer_state 写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE128_TMPDIR:-/tmp/cjgui-stage128-terminal-write-denial-packet-$$}"
UPSTREAM_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet.sh"
UPSTREAM_LOG="$TMP_DIR/rollback-fallback-denial.log"
RESULT_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-terminal-write-denial-envelope-first-slice.packet"
ROLLBACK_FALLBACK_DENIAL_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_ROLLBACK_FALLBACK_DENIAL_ENVELOPE_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$UPSTREAM_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$UPSTREAM_PACKET_SCRIPT" ]]; then
  echo "cjgui terminal write denial packet: missing executable script $UPSTREAM_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$UPSTREAM_PACKET_SCRIPT"; then
  echo "cjgui terminal write denial packet: syntax check failed $UPSTREAM_PACKET_SCRIPT" >&2
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
    echo "cjgui terminal write denial packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$ROLLBACK_FALLBACK_DENIAL_PACKET" ]]; then
  if env CJGUI_STAGE128_TMPDIR="/tmp/cjgui-stage128-upstream-rollback-fallback-denial-$$" \
    zsh "$UPSTREAM_PACKET_SCRIPT" > "$UPSTREAM_LOG" 2>&1; then
    ROLLBACK_FALLBACK_DENIAL_PACKET="$(grep -Eo 'rollback_fallback_denial_envelope_packet_path=[^[:space:]]+' "$UPSTREAM_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui terminal write denial packet: upstream packet failed" >&2
    echo "cjgui terminal write denial packet: log=$UPSTREAM_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$ROLLBACK_FALLBACK_DENIAL_PACKET" ]]; then
    echo "cjgui terminal write denial packet: provided packet missing $ROLLBACK_FALLBACK_DENIAL_PACKET" >&2
    exit 7
  fi
  echo "provided_rollback_fallback_denial_packet_used=true" > "$UPSTREAM_LOG"
fi

if [[ -z "$ROLLBACK_FALLBACK_DENIAL_PACKET" || ! -f "$ROLLBACK_FALLBACK_DENIAL_PACKET" ]]; then
  echo "cjgui terminal write denial packet: missing rollback fallback denial packet" >&2
  exit 8
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true" \
  "semantic_comparison_admitted_renderer_state_visibility_publication_denial_consumed=true" \
  "visibility_denial_bound_to_rollback_fallback_stop_line=true" \
  "rollback_fallback_state_write_denied=true" \
  "rollback_fallback_non_executable=true" \
  "terminal_write_denial_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$ROLLBACK_FALLBACK_DENIAL_PACKET" "$fact"
done

runtime_native_probe_execution="$(fact_value "$ROLLBACK_FALLBACK_DENIAL_PACKET" "runtime_native_probe_execution")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_packet=$ROLLBACK_FALLBACK_DENIAL_PACKET"
  echo "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true"
  echo "terminal_write_denial_envelope_materialized=true"
  echo "visibility_publication_denial_persisted_as_terminal_dry_run_fact=true"
  echo "rollback_fallback_denial_persisted_as_terminal_dry_run_fact=true"
  echo "frame_hash_unpublished_persisted_as_terminal_dry_run_fact=true"
  echo "terminal_renderer_state_write_denied=true"
  echo "terminal_write_denial_non_executable=true"
  echo "result_envelope_promoted_to_production_truth=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui terminal write denial packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet"
echo "cjgui terminal write denial packet: terminal_write_denial_envelope_packet_path=$RESULT_PACKET"
echo "cjgui terminal write denial packet: semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true"
echo "cjgui terminal write denial packet: renderer_state_write=false"
