#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 backing-store token result envelope，重新检查
# frame-hash persistence commit readiness。token denial 时 persistence commit
# 继续 fail-closed，且不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE132_TMPDIR:-/tmp/cjgui-stage132-persistence-commit-recheck-$$}"
TOKEN_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_backing_store_token_result_first_slice_packet.sh"
TOKEN_LOG="$TMP_DIR/backing-store-token-result.log"
RESULT_PACKET="$TMP_DIR/stage132-frame-hash-persistence-commit-readiness-recheck-first-slice.packet"
TOKEN_PACKET="${CJGUI_STAGE132_BACKING_STORE_TOKEN_RESULT_ENVELOPE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$TOKEN_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$TOKEN_PACKET_SCRIPT" ]]; then
  echo "cjgui stage132 persistence commit recheck packet: missing executable script $TOKEN_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$TOKEN_PACKET_SCRIPT"; then
  echo "cjgui stage132 persistence commit recheck packet: token script syntax failed" >&2
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
    echo "cjgui stage132 persistence commit recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$TOKEN_PACKET" ]]; then
  if env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage132-upstream-token-$$" \
    zsh "$TOKEN_PACKET_SCRIPT" > "$TOKEN_LOG" 2>&1; then
    TOKEN_PACKET="$(grep -Eo 'backing_store_token_result_envelope_packet_path=[^[:space:]]+' "$TOKEN_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage132 persistence commit recheck packet: token result packet failed" >&2
    echo "cjgui stage132 persistence commit recheck packet: log=$TOKEN_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$TOKEN_PACKET" ]]; then
    echo "cjgui stage132 persistence commit recheck packet: provided token packet missing $TOKEN_PACKET" >&2
    exit 7
  fi
  echo "provided_backing_store_token_result_envelope_packet_used=true" > "$TOKEN_LOG"
fi

if [[ -z "$TOKEN_PACKET" || ! -f "$TOKEN_PACKET" ]]; then
  echo "cjgui stage132 persistence commit recheck packet: missing token packet" >&2
  exit 8
fi

for fact in \
  "stage132_backing_store_token_result_envelope_first_slice_packet_passed=true" \
  "backing_store_token_result_envelope_ready=true" \
  "frame_hash_persistence_commit_recheck_input_prepared=true" \
  "frame_hash_persisted=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$TOKEN_PACKET" "$fact"
done

token_issued="$(fact_value "$TOKEN_PACKET" "backing_store_token_issued")"
token_denied="$(fact_value "$TOKEN_PACKET" "backing_store_token_issue_denied")"
token_denial_reason="$(fact_value "$TOKEN_PACKET" "backing_store_token_denial_reason")"
positive_live_probe="$(fact_value "$TOKEN_PACKET" "positive_live_probe_observed")"
nonzero_hash="$(fact_value "$TOKEN_PACKET" "nonzero_frame_hash_observed")"
host_absent="$(fact_value "$TOKEN_PACKET" "host_runtime_limitation_absent")"
harness_absent="$(fact_value "$TOKEN_PACKET" "cjgui_harness_gap_absent")"
host_limit="$(fact_value "$TOKEN_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$TOKEN_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$TOKEN_PACKET" "runtime_native_probe_execution")"

if [[ "$token_issued" == "true" && "$positive_live_probe" == "true" && "$nonzero_hash" == "true" ]]; then
  frame_hash_persistence_commit_admitted=true
  frame_hash_persistence_commit_block_reason=none
else
  frame_hash_persistence_commit_admitted=false
  frame_hash_persistence_commit_block_reason="$token_denial_reason"
fi

{
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_packet_version=1"
  echo "backing_store_token_result_envelope_packet=$TOKEN_PACKET"
  echo "backing_store_token_result_envelope_consumed=true"
  echo "frame_hash_persistence_commit_readiness_recheck_ready=true"
  echo "frame_hash_persistence_commit_still_blocked_by_token_result=$token_denied"
  echo "frame_hash_persistence_commit_block_reason=$frame_hash_persistence_commit_block_reason"
  echo "backing_store_token_issued=$token_issued"
  echo "backing_store_token_issue_denied=$token_denied"
  echo "positive_live_probe_observed=$positive_live_probe"
  echo "nonzero_frame_hash_observed=$nonzero_hash"
  echo "host_runtime_limitation_absent=$host_absent"
  echo "cjgui_harness_gap_absent=$harness_absent"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "positive_probe_still_required_for_frame_hash_persistence_commit=true"
  echo "nonzero_frame_hash_still_required_for_frame_hash_persistence_commit=true"
  echo "frame_hash_persistence_commit_admitted=$frame_hash_persistence_commit_admitted"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_truth_promotion_admitted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "positive_probe_materialization_or_production_truth_token_gate_next_route_prepared=true"
  echo "next_route=frame_hash_persistence_positive_probe_materialization_or_production_truth_token_gate_recheck_first_slice"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage132 persistence commit recheck packet: route_classification=stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_packet"
echo "cjgui stage132 persistence commit recheck packet: frame_hash_persistence_commit_readiness_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage132 persistence commit recheck packet: frame_hash_persistence_commit_admitted=$frame_hash_persistence_commit_admitted"
echo "cjgui stage132 persistence commit recheck packet: renderer_state_write=false"
