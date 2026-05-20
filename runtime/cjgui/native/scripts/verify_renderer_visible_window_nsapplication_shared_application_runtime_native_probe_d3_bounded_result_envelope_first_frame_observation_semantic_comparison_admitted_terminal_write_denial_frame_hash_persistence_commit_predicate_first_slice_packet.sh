#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage131 promotion persistence recheck packet，
# 生成 stage132 backing-store commit predicate packet。它只计算 admission
# predicate，不写 state，不记录真实 hash value。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE132_TMPDIR:-/tmp/cjgui-stage132-commit-predicate-$$}"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_persistence_recheck_first_slice_packet.sh"
RECHECK_LOG="$TMP_DIR/stage131-promotion-persistence-recheck.log"
RESULT_PACKET="$TMP_DIR/stage132-positive-probe-backing-store-commit-predicate-first-slice.packet"
RECHECK_PACKET="${CJGUI_STAGE132_STAGE131_PROMOTION_PERSISTENCE_RECHECK_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$RECHECK_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$RECHECK_PACKET_SCRIPT" ]]; then
  echo "cjgui stage132 commit predicate packet: missing executable script $RECHECK_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$RECHECK_PACKET_SCRIPT"; then
  echo "cjgui stage132 commit predicate packet: stage131 recheck script syntax failed" >&2
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
    echo "cjgui stage132 commit predicate packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$RECHECK_PACKET" ]]; then
  if env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage132-upstream-stage131-recheck-$$" \
    zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_LOG" 2>&1; then
    RECHECK_PACKET="$(grep -Eo 'production_truth_promotion_persistence_recheck_packet_path=[^[:space:]]+' "$RECHECK_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage132 commit predicate packet: stage131 promotion persistence recheck packet failed" >&2
    echo "cjgui stage132 commit predicate packet: log=$RECHECK_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$RECHECK_PACKET" ]]; then
    echo "cjgui stage132 commit predicate packet: provided stage131 recheck packet missing $RECHECK_PACKET" >&2
    exit 7
  fi
  echo "provided_stage131_promotion_persistence_recheck_packet_used=true" > "$RECHECK_LOG"
fi

if [[ -z "$RECHECK_PACKET" || ! -f "$RECHECK_PACKET" ]]; then
  echo "cjgui stage132 commit predicate packet: missing stage131 recheck packet" >&2
  exit 8
fi

for fact in \
  "stage131_production_truth_promotion_persistence_recheck_first_slice_packet_passed=true" \
  "production_truth_promotion_persistence_recheck_ready=true" \
  "positive_probe_backing_store_commit_predicate_next_route_prepared=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$RECHECK_PACKET" "$fact"
done

positive_input="$(fact_value "$RECHECK_PACKET" "positive_probe_frame_hash_input_available")"
host_limit="$(fact_value "$RECHECK_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$RECHECK_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$RECHECK_PACKET" "runtime_native_probe_execution")"

positive_live_probe_observed="$positive_input"
nonzero_frame_hash_observed="$positive_input"
if [[ "$host_limit" == "false" ]]; then
  host_runtime_limitation_absent=true
else
  host_runtime_limitation_absent=false
fi
if [[ "$harness_gap" == "false" ]]; then
  cjgui_harness_gap_absent=true
else
  cjgui_harness_gap_absent=false
fi

if [[ "$positive_live_probe_observed" == "true" &&
      "$nonzero_frame_hash_observed" == "true" &&
      "$host_runtime_limitation_absent" == "true" &&
      "$cjgui_harness_gap_absent" == "true" ]]; then
  backing_store_commit_predicate_satisfied=true
else
  backing_store_commit_predicate_satisfied=false
fi

{
  echo "stage132_positive_probe_backing_store_commit_predicate_first_slice_packet_version=1"
  echo "production_truth_promotion_persistence_recheck_packet=$RECHECK_PACKET"
  echo "production_truth_promotion_persistence_recheck_consumed=true"
  echo "positive_probe_backing_store_commit_predicate_ready=true"
  echo "backing_store_commit_requires_positive_probe=true"
  echo "backing_store_commit_requires_nonzero_frame_hash=true"
  echo "backing_store_commit_requires_host_runtime_limitation_absent=true"
  echo "backing_store_commit_requires_harness_gap_absent=true"
  echo "positive_live_probe_observed=$positive_live_probe_observed"
  echo "nonzero_frame_hash_observed=$nonzero_frame_hash_observed"
  echo "nonzero_frame_hash_fact_source=positive_probe_frame_hash_input_available"
  echo "host_runtime_limitation_absent=$host_runtime_limitation_absent"
  echo "cjgui_harness_gap_absent=$cjgui_harness_gap_absent"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "backing_store_commit_predicate_satisfied=$backing_store_commit_predicate_satisfied"
  echo "backing_store_commit_non_mutating=true"
  echo "backing_store_token_issued=false"
  echo "backing_store_token_result_envelope_input_prepared=true"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "stage132_positive_probe_backing_store_commit_predicate_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage132 commit predicate packet: route_classification=stage132_positive_probe_backing_store_commit_predicate_first_slice_packet"
echo "cjgui stage132 commit predicate packet: positive_probe_backing_store_commit_predicate_packet_path=$RESULT_PACKET"
echo "cjgui stage132 commit predicate packet: backing_store_commit_predicate_satisfied=$backing_store_commit_predicate_satisfied"
echo "cjgui stage132 commit predicate packet: renderer_state_write=false"
