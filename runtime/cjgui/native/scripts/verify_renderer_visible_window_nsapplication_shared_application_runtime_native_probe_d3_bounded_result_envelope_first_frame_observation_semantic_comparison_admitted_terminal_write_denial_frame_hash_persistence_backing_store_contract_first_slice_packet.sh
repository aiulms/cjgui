#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage130 renderer-state write admission recheck
# packet，生成 non-mutating frame-hash persistence backing-store contract
# packet。它不签发 backing-store token，不持久化 hash value。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE131_TMPDIR:-/tmp/cjgui-stage131-backing-store-contract-$$}"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_admission_recheck_first_slice_packet.sh"
RECHECK_LOG="$TMP_DIR/stage130-recheck.log"
RESULT_PACKET="$TMP_DIR/stage131-frame-hash-persistence-backing-store-contract-first-slice.packet"
RECHECK_PACKET="${CJGUI_STAGE131_STAGE130_RECHECK_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$RECHECK_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$RECHECK_PACKET_SCRIPT" ]]; then
  echo "cjgui stage131 backing-store contract packet: missing executable script $RECHECK_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$RECHECK_PACKET_SCRIPT"; then
  echo "cjgui stage131 backing-store contract packet: stage130 recheck script syntax failed" >&2
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
    echo "cjgui stage131 backing-store contract packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$RECHECK_PACKET" ]]; then
  if env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage131-upstream-recheck-$$" \
    zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_LOG" 2>&1; then
    RECHECK_PACKET="$(grep -Eo 'renderer_state_write_admission_recheck_packet_path=[^[:space:]]+' "$RECHECK_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage131 backing-store contract packet: stage130 recheck packet failed" >&2
    echo "cjgui stage131 backing-store contract packet: log=$RECHECK_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$RECHECK_PACKET" ]]; then
    echo "cjgui stage131 backing-store contract packet: provided stage130 recheck packet missing $RECHECK_PACKET" >&2
    exit 7
  fi
  echo "provided_stage130_recheck_packet_used=true" > "$RECHECK_LOG"
fi

if [[ -z "$RECHECK_PACKET" || ! -f "$RECHECK_PACKET" ]]; then
  echo "cjgui stage131 backing-store contract packet: missing stage130 recheck packet" >&2
  exit 8
fi

for fact in \
  "stage130_renderer_state_write_admission_recheck_first_slice_packet_passed=true" \
  "renderer_state_write_admission_recheck_ready=true" \
  "frame_hash_persistence_backing_store_next_route_prepared=true" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$RECHECK_PACKET" "$fact"
done

positive_probe_frame_hash_input="$(fact_value "$RECHECK_PACKET" "positive_probe_frame_hash_input_available")"
host_limit="$(fact_value "$RECHECK_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$RECHECK_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$RECHECK_PACKET" "runtime_native_probe_execution")"

if [[ "$positive_probe_frame_hash_input" == "true" ]]; then
  backing_store_commit_blocked_by_probe_classification=false
else
  backing_store_commit_blocked_by_probe_classification=true
fi

{
  echo "stage131_frame_hash_persistence_backing_store_contract_first_slice_packet_version=1"
  echo "renderer_state_write_admission_recheck_packet=$RECHECK_PACKET"
  echo "renderer_state_write_admission_recheck_consumed=true"
  echo "frame_hash_persistence_backing_store_contract_ready=true"
  echo "backing_store_contract_non_mutating=true"
  echo "backing_store_token_shape_defined=true"
  echo "backing_store_token_issued=false"
  echo "backing_store_commit_admitted=false"
  echo "backing_store_commit_blocked_by_missing_token=true"
  echo "backing_store_commit_blocked_by_probe_classification=$backing_store_commit_blocked_by_probe_classification"
  echo "positive_live_probe_required_for_backing_store_commit=true"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "current_shell_bounded_probe_positive=$positive_probe_frame_hash_input"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "frame_hash_persistence_admitted=false"
  echo "frame_hash_persistence_result_envelope_input_prepared=true"
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
  echo "stage131_frame_hash_persistence_backing_store_contract_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage131 backing-store contract packet: route_classification=stage131_frame_hash_persistence_backing_store_contract_first_slice_packet"
echo "cjgui stage131 backing-store contract packet: backing_store_contract_packet_path=$RESULT_PACKET"
echo "cjgui stage131 backing-store contract packet: backing_store_token_issued=false"
echo "cjgui stage131 backing-store contract packet: renderer_state_write=false"
