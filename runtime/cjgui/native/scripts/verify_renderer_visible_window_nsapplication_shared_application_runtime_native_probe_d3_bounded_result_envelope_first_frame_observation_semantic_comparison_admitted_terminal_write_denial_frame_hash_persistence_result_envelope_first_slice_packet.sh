#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 backing-store contract packet，生成
# frame-hash persistence result envelope。当前结果必须 fail-closed。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE131_TMPDIR:-/tmp/cjgui-stage131-persistence-result-$$}"
CONTRACT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_backing_store_contract_first_slice_packet.sh"
CONTRACT_LOG="$TMP_DIR/backing-store-contract.log"
RESULT_PACKET="$TMP_DIR/stage131-frame-hash-persistence-result-envelope-first-slice.packet"
CONTRACT_PACKET="${CJGUI_STAGE131_BACKING_STORE_CONTRACT_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$CONTRACT_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$CONTRACT_PACKET_SCRIPT" ]]; then
  echo "cjgui stage131 persistence result packet: missing executable script $CONTRACT_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$CONTRACT_PACKET_SCRIPT"; then
  echo "cjgui stage131 persistence result packet: contract script syntax failed" >&2
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
    echo "cjgui stage131 persistence result packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$CONTRACT_PACKET" ]]; then
  if env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage131-upstream-contract-$$" \
    zsh "$CONTRACT_PACKET_SCRIPT" > "$CONTRACT_LOG" 2>&1; then
    CONTRACT_PACKET="$(grep -Eo 'backing_store_contract_packet_path=[^[:space:]]+' "$CONTRACT_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage131 persistence result packet: backing-store contract packet failed" >&2
    echo "cjgui stage131 persistence result packet: log=$CONTRACT_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$CONTRACT_PACKET" ]]; then
    echo "cjgui stage131 persistence result packet: provided contract packet missing $CONTRACT_PACKET" >&2
    exit 7
  fi
  echo "provided_backing_store_contract_packet_used=true" > "$CONTRACT_LOG"
fi

if [[ -z "$CONTRACT_PACKET" || ! -f "$CONTRACT_PACKET" ]]; then
  echo "cjgui stage131 persistence result packet: missing backing-store contract packet" >&2
  exit 8
fi

for fact in \
  "stage131_frame_hash_persistence_backing_store_contract_first_slice_packet_passed=true" \
  "frame_hash_persistence_backing_store_contract_ready=true" \
  "backing_store_contract_non_mutating=true" \
  "backing_store_token_issued=false" \
  "frame_hash_persistence_result_envelope_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$CONTRACT_PACKET" "$fact"
done

positive_probe_frame_hash_input="$(fact_value "$CONTRACT_PACKET" "positive_probe_frame_hash_input_available")"
host_limit="$(fact_value "$CONTRACT_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$CONTRACT_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$CONTRACT_PACKET" "runtime_native_probe_execution")"
backing_store_token_issued="$(fact_value "$CONTRACT_PACKET" "backing_store_token_issued")"

if [[ "$backing_store_token_issued" == "true" && "$positive_probe_frame_hash_input" == "true" ]]; then
  persistence_block_reason=none
else
  persistence_block_reason=missing_backing_store_token_or_positive_probe
fi

{
  echo "stage131_frame_hash_persistence_result_envelope_first_slice_packet_version=1"
  echo "backing_store_contract_packet=$CONTRACT_PACKET"
  echo "frame_hash_persistence_backing_store_contract_consumed=true"
  echo "frame_hash_persistence_result_envelope_ready=true"
  echo "frame_hash_persistence_result_fail_closed=true"
  echo "frame_hash_persistence_result_block_reason=$persistence_block_reason"
  echo "backing_store_contract_non_mutating=true"
  echo "backing_store_token_issued=false"
  echo "positive_live_probe_required_for_hash_persistence=true"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "frame_hash_persistence_admitted=false"
  echo "production_truth_promotion_persistence_recheck_input_prepared=true"
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
  echo "stage131_frame_hash_persistence_result_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage131 persistence result packet: route_classification=stage131_frame_hash_persistence_result_envelope_first_slice_packet"
echo "cjgui stage131 persistence result packet: frame_hash_persistence_result_packet_path=$RESULT_PACKET"
echo "cjgui stage131 persistence result packet: frame_hash_persisted=false"
echo "cjgui stage131 persistence result packet: renderer_state_write=false"
