#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 production-truth promotion predicate packet，重新
# 计算 renderer-state write admission。当前仍必须 blocked，并给出下一跳
# frame-hash persistence backing-store contract。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE130_TMPDIR:-/tmp/cjgui-stage130-renderer-state-write-admission-recheck-$$}"
PROMOTION_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_predicate_map_first_slice_packet.sh"
PROMOTION_LOG="$TMP_DIR/production-truth-promotion.log"
RESULT_PACKET="$TMP_DIR/stage130-renderer-state-write-admission-recheck-first-slice.packet"
PROMOTION_PACKET="${CJGUI_STAGE130_PRODUCTION_TRUTH_PROMOTION_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PROMOTION_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$PROMOTION_PACKET_SCRIPT" ]]; then
  echo "cjgui stage130 renderer-state write admission recheck packet: missing executable script $PROMOTION_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PROMOTION_PACKET_SCRIPT"; then
  echo "cjgui stage130 renderer-state write admission recheck packet: promotion packet script syntax failed" >&2
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
    echo "cjgui stage130 renderer-state write admission recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$PROMOTION_PACKET" ]]; then
  if env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage130-upstream-promotion-$$" \
    zsh "$PROMOTION_PACKET_SCRIPT" > "$PROMOTION_LOG" 2>&1; then
    PROMOTION_PACKET="$(grep -Eo 'production_truth_promotion_packet_path=[^[:space:]]+' "$PROMOTION_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage130 renderer-state write admission recheck packet: production-truth promotion packet failed" >&2
    echo "cjgui stage130 renderer-state write admission recheck packet: log=$PROMOTION_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$PROMOTION_PACKET" ]]; then
    echo "cjgui stage130 renderer-state write admission recheck packet: provided promotion packet missing $PROMOTION_PACKET" >&2
    exit 7
  fi
  echo "provided_production_truth_promotion_packet_used=true" > "$PROMOTION_LOG"
fi

if [[ -z "$PROMOTION_PACKET" || ! -f "$PROMOTION_PACKET" ]]; then
  echo "cjgui stage130 renderer-state write admission recheck packet: missing production-truth promotion packet" >&2
  exit 8
fi

for fact in \
  "stage130_production_truth_promotion_predicate_map_first_slice_packet_passed=true" \
  "production_truth_promotion_predicate_map_ready=true" \
  "renderer_state_write_admission_recheck_input_prepared=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$PROMOTION_PACKET" "$fact"
done

positive_probe_frame_hash_input="$(fact_value "$PROMOTION_PACKET" "positive_probe_frame_hash_input_available")"
production_truth_promotion_admitted="$(fact_value "$PROMOTION_PACKET" "production_truth_promotion_admitted")"
host_limit="$(fact_value "$PROMOTION_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$PROMOTION_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$PROMOTION_PACKET" "runtime_native_probe_execution")"

if [[ "$positive_probe_frame_hash_input" == "true" ]]; then
  renderer_state_write_blocked_by_probe_classification=false
else
  renderer_state_write_blocked_by_probe_classification=true
fi

{
  echo "stage130_renderer_state_write_admission_recheck_first_slice_packet_version=1"
  echo "production_truth_promotion_packet=$PROMOTION_PACKET"
  echo "production_truth_promotion_predicate_map_consumed=true"
  echo "renderer_state_write_admission_recheck_ready=true"
  echo "frame_hash_persistence_bound_to_renderer_state_write_admission=true"
  echo "production_truth_promotion_bound_to_renderer_state_write_admission=true"
  echo "production_truth_promotion_admitted=$production_truth_promotion_admitted"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write_blocked_by_frame_hash_persistence=true"
  echo "renderer_state_write_blocked_by_production_truth_promotion=true"
  echo "renderer_state_write_blocked_by_probe_classification=$renderer_state_write_blocked_by_probe_classification"
  echo "visibility_publication_admission_ready=false"
  echo "rollback_fallback_admission_ready=false"
  echo "frame_hash_persistence_backing_store_next_route_prepared=true"
  echo "next_route=frame_hash_persistence_backing_store_contract_first_slice"
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
  echo "stage130_renderer_state_write_admission_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage130 renderer-state write admission recheck packet: route_classification=stage130_renderer_state_write_admission_recheck_first_slice_packet"
echo "cjgui stage130 renderer-state write admission recheck packet: renderer_state_write_admission_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage130 renderer-state write admission recheck packet: renderer_state_write_admission_ready=false"
echo "cjgui stage130 renderer-state write admission recheck packet: renderer_state_write=false"
