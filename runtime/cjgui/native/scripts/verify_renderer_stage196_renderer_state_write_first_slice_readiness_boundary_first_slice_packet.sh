#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage196 first-slice readiness boundary packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE196_PACKET_TMPDIR:-/tmp/cjgui-stage196-renderer-state-write-first-slice-readiness-boundary-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage196_renderer_state_write_first_slice_readiness_boundary_first_slice_owner.sh"
STAGE195_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage195_renderer_state_write_admission_join_decision_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE195_LOG="$TMP_DIR/stage195.log"
RESULT_PACKET="$TMP_DIR/stage196-renderer-state-write-first-slice-readiness-boundary-first-slice.packet"
STAGE195_SUITE_PACKET="${CJGUI_STAGE195_RENDERER_STATE_WRITE_ADMISSION_JOIN_DECISION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage195"
: > "$OWNER_LOG"
: > "$STAGE195_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE195_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: owner probe failed" >&2
  echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage196_renderer_state_write_first_slice_readiness_boundary_owner_present=true" \
  "stage195_admission_join_decision_required=true" \
  "renderer_state_write_first_slice_readiness_boundary_materialized=true" \
  "admission_join_decision_bound_to_visibility_hold=true" \
  "visibility_publication_hold_receipt_materialized=true" \
  "renderer_state_write_readiness_boundary_packet_materialized=true" \
  "stage197_renderer_state_write_production_truth_semantic_recheck_input_prepared=true" \
  "renderer_state_write_first_slice_boundary_non_mutating=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage195_input_mode="generated_stage195_suite_packet"
if [[ -n "$STAGE195_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE195_SUITE_PACKET" ]]; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: provided stage195 suite packet missing $STAGE195_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage195_suite_packet_used=true" > "$STAGE195_LOG"
  stage195_input_mode="provided_stage195_suite_packet"
else
  if ! env CJGUI_STAGE195_TMPDIR="$TMP_DIR/stage195" zsh "$STAGE195_SUITE_SCRIPT" > "$STAGE195_LOG" 2>&1; then
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: stage195 suite failed" >&2
    echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: log=$STAGE195_LOG" >&2
    exit 8
  fi
  STAGE195_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE195_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE195_SUITE_PACKET" || ! -f "$STAGE195_SUITE_PACKET" ]]; then
  echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: missing stage195 suite packet" >&2
  exit 9
fi
for fact in \
  "stage195_renderer_state_write_admission_join_decision_suite_passed=true" \
  "renderer_state_write_admission_join_decision_ready=true" \
  "production_truth_recheck_request_materialized=true" \
  "semantic_admission_recheck_request_materialized=true" \
  "stage196_renderer_state_write_first_slice_readiness_boundary_input_prepared=true" \
  "renderer_state_write_admission_decision_denied=true" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE195_SUITE_PACKET" "$fact"
done

stage195_route="$(fact_value "$STAGE195_SUITE_PACKET" "renderer_state_write_admission_join_decision_route_classification")"
stage196_route="renderer_state_write_first_slice_readiness_boundary_ready_visibility_held"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage196_renderer_state_write_first_slice_readiness_boundary_packet_version=1"
  echo "stage195_input_mode=$stage195_input_mode"
  echo "stage195_suite_packet=$STAGE195_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage195_log=$STAGE195_LOG"
  echo "stage195_admission_join_decision_consumed=true"
  echo "stage195_admission_join_decision_route_classification=$stage195_route"
  echo "renderer_state_write_first_slice_readiness_boundary_route_classification=$stage196_route"
  echo "renderer_state_write_first_slice_readiness_boundary_ready=true"
  echo "renderer_state_write_first_slice_readiness_boundary_source_ready=true"
  echo "renderer_state_write_first_slice_readiness_boundary_runtime_admitted=false"
  echo "renderer_state_write_first_slice_readiness_boundary_materialized=true"
  echo "admission_join_decision_bound_to_visibility_hold=true"
  echo "visibility_publication_hold_receipt_materialized=true"
  echo "renderer_state_write_readiness_boundary_packet_materialized=true"
  echo "stage197_renderer_state_write_production_truth_semantic_recheck_input_prepared=true"
  echo "renderer_state_write_first_slice_boundary_non_mutating=true"
  echo "renderer_state_write_eligibility=false"
  echo "production_truth_recheck_request_materialized=true"
  echo "semantic_admission_recheck_request_materialized=true"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage197_renderer_state_write_production_truth_semantic_recheck_bridge_after_first_slice_readiness_boundary"
  echo "stage196_renderer_state_write_first_slice_readiness_boundary_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: route_classification=$stage196_route"
echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: first_slice_readiness_boundary_packet_path=$RESULT_PACKET"
echo "cjgui stage196 renderer_state write first-slice readiness boundary packet: renderer_state_write=false"
