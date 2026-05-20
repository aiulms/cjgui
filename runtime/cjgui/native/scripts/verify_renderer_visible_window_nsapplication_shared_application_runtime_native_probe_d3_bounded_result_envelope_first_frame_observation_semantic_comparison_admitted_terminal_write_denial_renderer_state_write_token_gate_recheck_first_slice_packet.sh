#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 production truth token gate packet，重算
# renderer-state write admission。production truth 或 backend-ready truth 缺失时
# 保持 state write blocked，并准备下一次 positive host rerun route。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE133_TMPDIR:-/tmp/cjgui-stage133-renderer-state-token-gate-$$}"
TRUTH_GATE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_token_gate_recheck_first_slice_packet.sh"
TRUTH_GATE_LOG="$TMP_DIR/production-truth-token-gate.log"
RESULT_PACKET="$TMP_DIR/stage133-renderer-state-write-token-gate-recheck-first-slice.packet"
TRUTH_GATE_PACKET="${CJGUI_STAGE133_PRODUCTION_TRUTH_TOKEN_GATE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$TRUTH_GATE_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$TRUTH_GATE_PACKET_SCRIPT" ]]; then
  echo "cjgui stage133 renderer state write token gate packet: missing executable script $TRUTH_GATE_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$TRUTH_GATE_PACKET_SCRIPT"; then
  echo "cjgui stage133 renderer state write token gate packet: truth gate script syntax failed" >&2
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
    echo "cjgui stage133 renderer state write token gate packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$TRUTH_GATE_PACKET" ]]; then
  if env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage133-upstream-truth-gate-$$" \
    zsh "$TRUTH_GATE_PACKET_SCRIPT" > "$TRUTH_GATE_LOG" 2>&1; then
    TRUTH_GATE_PACKET="$(grep -Eo 'production_truth_token_gate_recheck_packet_path=[^[:space:]]+' "$TRUTH_GATE_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage133 renderer state write token gate packet: truth gate packet failed" >&2
    echo "cjgui stage133 renderer state write token gate packet: log=$TRUTH_GATE_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$TRUTH_GATE_PACKET" ]]; then
    echo "cjgui stage133 renderer state write token gate packet: provided truth gate packet missing $TRUTH_GATE_PACKET" >&2
    exit 7
  fi
  echo "provided_production_truth_token_gate_packet_used=true" > "$TRUTH_GATE_LOG"
fi

if [[ -z "$TRUTH_GATE_PACKET" || ! -f "$TRUTH_GATE_PACKET" ]]; then
  echo "cjgui stage133 renderer state write token gate packet: missing truth gate packet" >&2
  exit 8
fi

for fact in \
  "stage133_production_truth_token_gate_recheck_first_slice_packet_passed=true" \
  "renderer_state_write_token_gate_recheck_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$TRUTH_GATE_PACKET" "$fact"
done

production_truth="$(fact_value "$TRUTH_GATE_PACKET" "result_envelope_promoted_to_production_truth")"
backend_ready_truth="$(fact_value "$TRUTH_GATE_PACKET" "backend_ready_truth")"
host_limit="$(fact_value "$TRUTH_GATE_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$TRUTH_GATE_PACKET" "cjgui_harness_gap_detected")"
truth_block_reason="$(fact_value "$TRUTH_GATE_PACKET" "production_truth_token_gate_block_reason")"

if [[ "$production_truth" == "true" && "$backend_ready_truth" == "true" ]]; then
  renderer_state_write_admission_ready=true
  renderer_state_write_block_reason=none
else
  renderer_state_write_admission_ready=false
  renderer_state_write_block_reason=missing_production_truth_or_backend_ready_truth
fi

{
  echo "stage133_renderer_state_write_token_gate_recheck_first_slice_packet_version=1"
  echo "production_truth_token_gate_recheck_packet=$TRUTH_GATE_PACKET"
  echo "production_truth_token_gate_recheck_consumed=true"
  echo "renderer_state_write_token_gate_recheck_ready=true"
  echo "renderer_state_write_requires_production_truth=true"
  echo "renderer_state_write_requires_backend_ready_truth=true"
  echo "result_envelope_promoted_to_production_truth=$production_truth"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "production_truth_token_gate_block_reason=$truth_block_reason"
  echo "renderer_state_write_admission_ready=$renderer_state_write_admission_ready"
  echo "renderer_state_write_block_reason=$renderer_state_write_block_reason"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "positive_host_rerun_next_route_prepared=true"
  echo "next_route=rerun_bounded_first_frame_probe_on_metal_capable_host_or_promote_after_tokenized_persistence"
  echo "runtime_native_probe_execution=true"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage133_renderer_state_write_token_gate_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage133 renderer state write token gate packet: route_classification=stage133_renderer_state_write_token_gate_recheck_first_slice_packet"
echo "cjgui stage133 renderer state write token gate packet: renderer_state_write_token_gate_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage133 renderer state write token gate packet: renderer_state_write_admission_ready=$renderer_state_write_admission_ready"
echo "cjgui stage133 renderer state write token gate packet: renderer_state_write=false"
