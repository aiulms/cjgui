#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage132 backing-store commit predicate packet，
# 生成 backing-store token result envelope。当前 shell 缺 positive/nonzero
# input 且有宿主限制时必须 denial。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE132_TMPDIR:-/tmp/cjgui-stage132-backing-store-token-result-$$}"
PREDICATE_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_commit_predicate_first_slice_packet.sh"
PREDICATE_LOG="$TMP_DIR/commit-predicate.log"
RESULT_PACKET="$TMP_DIR/stage132-backing-store-token-result-envelope-first-slice.packet"
PREDICATE_PACKET="${CJGUI_STAGE132_POSITIVE_PROBE_BACKING_STORE_COMMIT_PREDICATE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PREDICATE_LOG"
: > "$RESULT_PACKET"

if [[ ! -x "$PREDICATE_PACKET_SCRIPT" ]]; then
  echo "cjgui stage132 backing-store token packet: missing executable script $PREDICATE_PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PREDICATE_PACKET_SCRIPT"; then
  echo "cjgui stage132 backing-store token packet: predicate script syntax failed" >&2
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
    echo "cjgui stage132 backing-store token packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$PREDICATE_PACKET" ]]; then
  if env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage132-upstream-predicate-$$" \
    zsh "$PREDICATE_PACKET_SCRIPT" > "$PREDICATE_LOG" 2>&1; then
    PREDICATE_PACKET="$(grep -Eo 'positive_probe_backing_store_commit_predicate_packet_path=[^[:space:]]+' "$PREDICATE_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage132 backing-store token packet: predicate packet failed" >&2
    echo "cjgui stage132 backing-store token packet: log=$PREDICATE_LOG" >&2
    exit 6
  fi
else
  if [[ ! -f "$PREDICATE_PACKET" ]]; then
    echo "cjgui stage132 backing-store token packet: provided predicate packet missing $PREDICATE_PACKET" >&2
    exit 7
  fi
  echo "provided_positive_probe_backing_store_commit_predicate_packet_used=true" > "$PREDICATE_LOG"
fi

if [[ -z "$PREDICATE_PACKET" || ! -f "$PREDICATE_PACKET" ]]; then
  echo "cjgui stage132 backing-store token packet: missing predicate packet" >&2
  exit 8
fi

for fact in \
  "stage132_positive_probe_backing_store_commit_predicate_first_slice_packet_passed=true" \
  "positive_probe_backing_store_commit_predicate_ready=true" \
  "backing_store_commit_requires_positive_probe=true" \
  "backing_store_commit_requires_nonzero_frame_hash=true" \
  "backing_store_commit_requires_host_runtime_limitation_absent=true" \
  "backing_store_commit_requires_harness_gap_absent=true" \
  "backing_store_token_result_envelope_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$PREDICATE_PACKET" "$fact"
done

positive_live_probe="$(fact_value "$PREDICATE_PACKET" "positive_live_probe_observed")"
nonzero_hash="$(fact_value "$PREDICATE_PACKET" "nonzero_frame_hash_observed")"
host_absent="$(fact_value "$PREDICATE_PACKET" "host_runtime_limitation_absent")"
harness_absent="$(fact_value "$PREDICATE_PACKET" "cjgui_harness_gap_absent")"
host_limit="$(fact_value "$PREDICATE_PACKET" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$PREDICATE_PACKET" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$PREDICATE_PACKET" "runtime_native_probe_execution")"
predicate_satisfied="$(fact_value "$PREDICATE_PACKET" "backing_store_commit_predicate_satisfied")"

if [[ "$predicate_satisfied" == "true" ]]; then
  backing_store_token_issued=true
  backing_store_token_issue_denied=false
  backing_store_token_denial_reason=none
else
  backing_store_token_issued=false
  backing_store_token_issue_denied=true
  backing_store_token_denial_reason=missing_positive_live_probe_or_nonzero_frame_hash_or_host_limit
fi

{
  echo "stage132_backing_store_token_result_envelope_first_slice_packet_version=1"
  echo "positive_probe_backing_store_commit_predicate_packet=$PREDICATE_PACKET"
  echo "positive_probe_backing_store_commit_predicate_consumed=true"
  echo "backing_store_token_result_envelope_ready=true"
  echo "backing_store_token_requires_satisfied_commit_predicate=true"
  echo "positive_live_probe_observed=$positive_live_probe"
  echo "nonzero_frame_hash_observed=$nonzero_hash"
  echo "host_runtime_limitation_absent=$host_absent"
  echo "cjgui_harness_gap_absent=$harness_absent"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "backing_store_commit_predicate_satisfied=$predicate_satisfied"
  echo "backing_store_token_issue_denied=$backing_store_token_issue_denied"
  echo "backing_store_token_denial_reason=$backing_store_token_denial_reason"
  echo "backing_store_token_issued=$backing_store_token_issued"
  echo "frame_hash_persistence_commit_recheck_input_prepared=true"
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
  echo "stage132_backing_store_token_result_envelope_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage132 backing-store token packet: route_classification=stage132_backing_store_token_result_envelope_first_slice_packet"
echo "cjgui stage132 backing-store token packet: backing_store_token_result_envelope_packet_path=$RESULT_PACKET"
echo "cjgui stage132 backing-store token packet: backing_store_token_issued=$backing_store_token_issued"
echo "cjgui stage132 backing-store token packet: renderer_state_write=false"
