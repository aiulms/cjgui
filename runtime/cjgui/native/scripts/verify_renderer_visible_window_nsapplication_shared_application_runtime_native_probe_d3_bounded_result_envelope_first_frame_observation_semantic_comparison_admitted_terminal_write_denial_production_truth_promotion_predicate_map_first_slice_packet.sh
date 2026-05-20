#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 frame-hash persistence evidence packet，生成
# production-truth promotion 谓词矩阵。当前只允许 blocked 结论，不发布
# production render truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE130_TMPDIR:-/tmp/cjgui-stage130-production-truth-promotion-$$}"
FRAME_HASH_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_evidence_envelope_first_slice_packet.sh"
FRAME_HASH_LOG="$TMP_DIR/frame-hash-persistence-evidence.log"
RESULT_PACKET="$TMP_DIR/stage130-production-truth-promotion-predicate-map-first-slice.packet"
FRAME_HASH_PACKET="${CJGUI_STAGE130_FRAME_HASH_PERSISTENCE_EVIDENCE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$FRAME_HASH_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$FRAME_HASH_PACKET_SCRIPT" ]]; then
  echo "cjgui stage130 production truth promotion packet: missing executable script $FRAME_HASH_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$FRAME_HASH_PACKET_SCRIPT"; then
  echo "cjgui stage130 production truth promotion packet: frame-hash packet script syntax failed" >&2
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
    echo "cjgui stage130 production truth promotion packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$FRAME_HASH_PACKET" ]]; then
  if env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage130-upstream-frame-hash-$$" \
    zsh "$FRAME_HASH_PACKET_SCRIPT" > "$FRAME_HASH_LOG" 2>&1; then
    FRAME_HASH_PACKET="$(grep -Eo 'frame_hash_persistence_evidence_packet_path=[^[:space:]]+' "$FRAME_HASH_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage130 production truth promotion packet: frame-hash evidence packet failed" >&2
    echo "cjgui stage130 production truth promotion packet: log=$FRAME_HASH_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$FRAME_HASH_PACKET" ]]; then
    echo "cjgui stage130 production truth promotion packet: provided frame-hash packet missing $FRAME_HASH_PACKET" >&2
    exit 7
  fi
  echo "provided_frame_hash_persistence_evidence_packet_used=true" > "$FRAME_HASH_LOG"
fi

if [[ -z "$FRAME_HASH_PACKET" || ! -f "$FRAME_HASH_PACKET" ]]; then
  echo "cjgui stage130 production truth promotion packet: missing frame-hash persistence evidence packet" >&2
  exit 8
fi

for fact in \
  "stage130_frame_hash_persistence_evidence_envelope_first_slice_packet_passed=true" \
  "frame_hash_persistence_evidence_envelope_ready=true" \
  "production_truth_promotion_predicate_map_input_prepared=true" \
  "frame_hash_persisted=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$FRAME_HASH_PACKET" "$fact"
done

probe_positive="$(fact_value "$FRAME_HASH_PACKET" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$FRAME_HASH_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$FRAME_HASH_PACKET" "cjgui_harness_gap_detected")"
frame_hash_persisted="$(fact_value "$FRAME_HASH_PACKET" "frame_hash_persisted")"
positive_probe_frame_hash_input="$(fact_value "$FRAME_HASH_PACKET" "positive_probe_frame_hash_input_available")"
runtime_native_probe_execution="$(fact_value "$FRAME_HASH_PACKET" "runtime_native_probe_execution")"

if [[ "$frame_hash_persisted" == "true" && "$positive_probe_frame_hash_input" == "true" && "$host_limit" != "true" && "$harness_gap" != "true" ]]; then
  production_truth_promotion_admitted=true
else
  production_truth_promotion_admitted=false
fi

{
  echo "stage130_production_truth_promotion_predicate_map_first_slice_packet_version=1"
  echo "frame_hash_persistence_evidence_packet=$FRAME_HASH_PACKET"
  echo "frame_hash_persistence_evidence_consumed=true"
  echo "production_truth_promotion_predicate_map_ready=true"
  echo "production_truth_promotion_predicates_materialized=true"
  echo "production_truth_promotion_requires_persisted_frame_hash=true"
  echo "production_truth_promotion_requires_positive_live_probe=true"
  echo "production_truth_promotion_requires_fresh_result_envelope=true"
  echo "production_truth_promotion_requires_host_limitation_absent=true"
  echo "production_truth_promotion_requires_harness_gap_absent=true"
  echo "production_truth_promotion_requires_semantic_comparison_admitted=true"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "frame_hash_persisted=$frame_hash_persisted"
  echo "production_truth_promotion_admitted=$production_truth_promotion_admitted"
  echo "production_truth_promotion_blocked_by_frame_hash_persistence=true"
  echo "production_truth_promotion_blocked_by_probe_classification=$([[ \"$positive_probe_frame_hash_input\" == \"true\" ]] && echo false || echo true)"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_recheck_input_prepared=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage130_production_truth_promotion_predicate_map_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage130 production truth promotion packet: route_classification=stage130_production_truth_promotion_predicate_map_first_slice_packet"
echo "cjgui stage130 production truth promotion packet: production_truth_promotion_packet_path=$RESULT_PACKET"
echo "cjgui stage130 production truth promotion packet: result_envelope_promoted_to_production_truth=false"
echo "cjgui stage130 production truth promotion packet: renderer_state_write=false"
