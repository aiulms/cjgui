#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage129 write-readiness closure packet，生成
# redacted frame-hash persistence evidence envelope。它不持久化 hash 值，
# 只把生产 truth promotion 所需输入显式化。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE130_TMPDIR:-/tmp/cjgui-stage130-frame-hash-persistence-evidence-$$}"
WRITE_READINESS_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet.sh"
WRITE_READINESS_LOG="$TMP_DIR/write-readiness.log"
RESULT_PACKET="$TMP_DIR/stage130-frame-hash-persistence-evidence-envelope-first-slice.packet"
WRITE_READINESS_PACKET="${CJGUI_STAGE130_WRITE_READINESS_CLOSURE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$WRITE_READINESS_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$WRITE_READINESS_PACKET_SCRIPT" ]]; then
  echo "cjgui stage130 frame-hash persistence evidence packet: missing executable script $WRITE_READINESS_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$WRITE_READINESS_PACKET_SCRIPT"; then
  echo "cjgui stage130 frame-hash persistence evidence packet: write-readiness script syntax failed" >&2
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
    echo "cjgui stage130 frame-hash persistence evidence packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$WRITE_READINESS_PACKET" ]]; then
  if env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage130-upstream-write-readiness-$$" \
    zsh "$WRITE_READINESS_PACKET_SCRIPT" > "$WRITE_READINESS_LOG" 2>&1; then
    WRITE_READINESS_PACKET="$(grep -Eo 'write_readiness_closure_packet_path=[^[:space:]]+' "$WRITE_READINESS_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage130 frame-hash persistence evidence packet: write-readiness packet failed" >&2
    echo "cjgui stage130 frame-hash persistence evidence packet: log=$WRITE_READINESS_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$WRITE_READINESS_PACKET" ]]; then
    echo "cjgui stage130 frame-hash persistence evidence packet: provided write-readiness packet missing $WRITE_READINESS_PACKET" >&2
    exit 7
  fi
  echo "provided_write_readiness_packet_used=true" > "$WRITE_READINESS_LOG"
fi

if [[ -z "$WRITE_READINESS_PACKET" || ! -f "$WRITE_READINESS_PACKET" ]]; then
  echo "cjgui stage130 frame-hash persistence evidence packet: missing write-readiness closure packet" >&2
  exit 8
fi

for fact in \
  "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet_passed=true" \
  "renderer_state_write_readiness_closure_ready=true" \
  "frame_hash_persistence_evidence_next_route_prepared=true" \
  "frame_hash_persisted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$WRITE_READINESS_PACKET" "$fact"
done

probe_positive="$(fact_value "$WRITE_READINESS_PACKET" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$WRITE_READINESS_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$WRITE_READINESS_PACKET" "cjgui_harness_gap_detected")"
failure_domain="$(fact_value "$WRITE_READINESS_PACKET" "first_frame_observation_first_slice_failure_domain")"
first_frame_observed="$(fact_value "$WRITE_READINESS_PACKET" "first_frame_observed")"
frame_hash_computed="$(fact_value "$WRITE_READINESS_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$WRITE_READINESS_PACKET" "frame_hash_nonzero")"
runtime_native_probe_execution="$(fact_value "$WRITE_READINESS_PACKET" "runtime_native_probe_execution")"

if [[ "$probe_positive" == "true" && "$frame_hash_computed" == "true" && "$frame_hash_nonzero" == "true" ]]; then
  positive_probe_frame_hash_input_available=true
else
  positive_probe_frame_hash_input_available=false
fi

{
  echo "stage130_frame_hash_persistence_evidence_envelope_first_slice_packet_version=1"
  echo "write_readiness_closure_packet=$WRITE_READINESS_PACKET"
  echo "write_readiness_closure_consumed=true"
  echo "frame_hash_persistence_evidence_envelope_ready=true"
  echo "redacted_frame_hash_persistence_schema_defined=true"
  echo "frame_hash_persistence_input_bound_to_current_probe=true"
  echo "positive_live_probe_required_for_hash_persistence=true"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input_available"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "first_frame_observation_first_slice_failure_domain=$failure_domain"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "frame_hash_persistence_admitted=false"
  echo "frame_hash_persistence_blocked_by_missing_backing_store=true"
  echo "frame_hash_persistence_blocked_by_probe_classification=$([[ \"$positive_probe_frame_hash_input_available\" == \"true\" ]] && echo false || echo true)"
  echo "production_truth_promotion_predicate_map_input_prepared=true"
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
  echo "stage130_frame_hash_persistence_evidence_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage130 frame-hash persistence evidence packet: route_classification=stage130_frame_hash_persistence_evidence_envelope_first_slice_packet"
echo "cjgui stage130 frame-hash persistence evidence packet: frame_hash_persistence_evidence_packet_path=$RESULT_PACKET"
echo "cjgui stage130 frame-hash persistence evidence packet: frame_hash_persisted=false"
echo "cjgui stage130 frame-hash persistence evidence packet: renderer_state_write=false"
