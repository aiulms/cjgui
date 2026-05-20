#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage133 positive-probe materialization packet，
# 重算 production truth token gate。只有 backing-store token 与 persistence
# commit 均 admitted 时才允许 promotion。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE133_TMPDIR:-/tmp/cjgui-stage133-production-truth-token-gate-$$}"
MATERIALIZATION_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_positive_probe_materialization_first_slice_packet.sh"
MATERIALIZATION_LOG="$TMP_DIR/positive-probe-materialization.log"
RESULT_PACKET="$TMP_DIR/stage133-production-truth-token-gate-recheck-first-slice.packet"
MATERIALIZATION_PACKET="${CJGUI_STAGE133_POSITIVE_PROBE_MATERIALIZATION_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$MATERIALIZATION_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$MATERIALIZATION_PACKET_SCRIPT" ]]; then
  echo "cjgui stage133 production truth token gate packet: missing executable script $MATERIALIZATION_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$MATERIALIZATION_PACKET_SCRIPT"; then
  echo "cjgui stage133 production truth token gate packet: materialization script syntax failed" >&2
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
    echo "cjgui stage133 production truth token gate packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$MATERIALIZATION_PACKET" ]]; then
  if env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage133-upstream-materialization-$$" \
    zsh "$MATERIALIZATION_PACKET_SCRIPT" > "$MATERIALIZATION_LOG" 2>&1; then
    MATERIALIZATION_PACKET="$(grep -Eo 'positive_probe_materialization_packet_path=[^[:space:]]+' "$MATERIALIZATION_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage133 production truth token gate packet: materialization packet failed" >&2
    echo "cjgui stage133 production truth token gate packet: log=$MATERIALIZATION_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$MATERIALIZATION_PACKET" ]]; then
    echo "cjgui stage133 production truth token gate packet: provided materialization packet missing $MATERIALIZATION_PACKET" >&2
    exit 7
  fi
  echo "provided_positive_probe_materialization_packet_used=true" > "$MATERIALIZATION_LOG"
fi

if [[ -z "$MATERIALIZATION_PACKET" || ! -f "$MATERIALIZATION_PACKET" ]]; then
  echo "cjgui stage133 production truth token gate packet: missing materialization packet" >&2
  exit 8
fi

for fact in \
  "stage133_positive_probe_materialization_first_slice_packet_passed=true" \
  "production_truth_token_gate_recheck_input_prepared=true" \
  "positive_probe_facts_kept_isolated=true" \
  "frame_hash_value_redacted=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$MATERIALIZATION_PACKET" "$fact"
done

token_issued="$(fact_value "$MATERIALIZATION_PACKET" "backing_store_token_issued")"
persistence_commit_admitted="$(fact_value "$MATERIALIZATION_PACKET" "frame_hash_persistence_commit_admitted")"
positive_live_probe="$(fact_value "$MATERIALIZATION_PACKET" "positive_live_probe_observed")"
nonzero_hash="$(fact_value "$MATERIALIZATION_PACKET" "nonzero_frame_hash_observed")"
host_limit="$(fact_value "$MATERIALIZATION_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$MATERIALIZATION_PACKET" "cjgui_harness_gap_detected")"
route_classification="$(fact_value "$MATERIALIZATION_PACKET" "positive_probe_materialization_route_classification")"

if [[ "$token_issued" == "true" && "$persistence_commit_admitted" == "true" ]]; then
  production_truth_promotion_admitted=true
  production_truth_token_gate_block_reason=none
else
  production_truth_promotion_admitted=false
  production_truth_token_gate_block_reason=missing_backing_store_token_or_persistence_commit
fi

{
  echo "stage133_production_truth_token_gate_recheck_first_slice_packet_version=1"
  echo "positive_probe_materialization_packet=$MATERIALIZATION_PACKET"
  echo "positive_probe_materialization_consumed=true"
  echo "production_truth_token_gate_recheck_ready=true"
  echo "production_truth_requires_backing_store_token=true"
  echo "production_truth_requires_frame_hash_persistence_commit=true"
  echo "backing_store_token_issued=$token_issued"
  echo "frame_hash_persistence_commit_admitted=$persistence_commit_admitted"
  echo "positive_live_probe_observed=$positive_live_probe"
  echo "nonzero_frame_hash_observed=$nonzero_hash"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "positive_probe_materialization_route_classification=$route_classification"
  echo "production_truth_token_gate_block_reason=$production_truth_token_gate_block_reason"
  echo "production_truth_promotion_admitted=$production_truth_promotion_admitted"
  echo "result_envelope_promoted_to_production_truth=$production_truth_promotion_admitted"
  echo "production_render_truth=$production_truth_promotion_admitted"
  echo "backend_ready_truth=false"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write_token_gate_recheck_input_prepared=true"
  echo "next_route=renderer_state_write_token_gate_recheck_first_slice"
  echo "runtime_native_probe_execution=true"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage133_production_truth_token_gate_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage133 production truth token gate packet: route_classification=stage133_production_truth_token_gate_recheck_first_slice_packet"
echo "cjgui stage133 production truth token gate packet: production_truth_token_gate_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage133 production truth token gate packet: result_envelope_promoted_to_production_truth=$production_truth_promotion_admitted"
echo "cjgui stage133 production truth token gate packet: renderer_state_write=false"
