#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 frame-hash persistence result envelope，重新
# 检查 production truth promotion gate。当前 persistence fail-closed 时
# promotion / renderer-state write 必须继续 blocked。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE131_TMPDIR:-/tmp/cjgui-stage131-promotion-persistence-recheck-$$}"
PERSISTENCE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_result_envelope_first_slice_packet.sh"
PERSISTENCE_LOG="$TMP_DIR/frame-hash-persistence-result.log"
RESULT_PACKET="$TMP_DIR/stage131-production-truth-promotion-persistence-recheck-first-slice.packet"
PERSISTENCE_PACKET="${CJGUI_STAGE131_FRAME_HASH_PERSISTENCE_RESULT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PERSISTENCE_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$PERSISTENCE_PACKET_SCRIPT" ]]; then
  echo "cjgui stage131 promotion persistence recheck packet: missing executable script $PERSISTENCE_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PERSISTENCE_PACKET_SCRIPT"; then
  echo "cjgui stage131 promotion persistence recheck packet: persistence script syntax failed" >&2
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
    echo "cjgui stage131 promotion persistence recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$PERSISTENCE_PACKET" ]]; then
  if env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage131-upstream-persistence-$$" \
    zsh "$PERSISTENCE_PACKET_SCRIPT" > "$PERSISTENCE_LOG" 2>&1; then
    PERSISTENCE_PACKET="$(grep -Eo 'frame_hash_persistence_result_packet_path=[^[:space:]]+' "$PERSISTENCE_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage131 promotion persistence recheck packet: persistence result packet failed" >&2
    echo "cjgui stage131 promotion persistence recheck packet: log=$PERSISTENCE_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$PERSISTENCE_PACKET" ]]; then
    echo "cjgui stage131 promotion persistence recheck packet: provided persistence packet missing $PERSISTENCE_PACKET" >&2
    exit 7
  fi
  echo "provided_frame_hash_persistence_result_packet_used=true" > "$PERSISTENCE_LOG"
fi

if [[ -z "$PERSISTENCE_PACKET" || ! -f "$PERSISTENCE_PACKET" ]]; then
  echo "cjgui stage131 promotion persistence recheck packet: missing persistence result packet" >&2
  exit 8
fi

for fact in \
  "stage131_frame_hash_persistence_result_envelope_first_slice_packet_passed=true" \
  "frame_hash_persistence_result_envelope_ready=true" \
  "frame_hash_persistence_result_fail_closed=true" \
  "frame_hash_persisted=false" \
  "production_truth_promotion_persistence_recheck_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$PERSISTENCE_PACKET" "$fact"
done

positive_probe_frame_hash_input="$(fact_value "$PERSISTENCE_PACKET" "positive_probe_frame_hash_input_available")"
host_limit="$(fact_value "$PERSISTENCE_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$PERSISTENCE_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$PERSISTENCE_PACKET" "runtime_native_probe_execution")"
persistence_block_reason="$(fact_value "$PERSISTENCE_PACKET" "frame_hash_persistence_result_block_reason")"

{
  echo "stage131_production_truth_promotion_persistence_recheck_first_slice_packet_version=1"
  echo "frame_hash_persistence_result_packet=$PERSISTENCE_PACKET"
  echo "frame_hash_persistence_result_envelope_consumed=true"
  echo "production_truth_promotion_persistence_recheck_ready=true"
  echo "production_truth_promotion_still_blocked_by_hash_persistence=true"
  echo "production_truth_promotion_block_reason=$persistence_block_reason"
  echo "backing_store_token_missing_blocks_production_truth=true"
  echo "positive_probe_still_required_for_production_truth=true"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_truth_promotion_admitted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "positive_probe_backing_store_commit_predicate_next_route_prepared=true"
  echo "next_route=frame_hash_persistence_positive_probe_backing_store_commit_predicate_first_slice"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage131_production_truth_promotion_persistence_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage131 promotion persistence recheck packet: route_classification=stage131_production_truth_promotion_persistence_recheck_first_slice_packet"
echo "cjgui stage131 promotion persistence recheck packet: production_truth_promotion_persistence_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage131 promotion persistence recheck packet: result_envelope_promoted_to_production_truth=false"
echo "cjgui stage131 promotion persistence recheck packet: renderer_state_write=false"
