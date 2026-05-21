#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage177 first-slice readiness decision packet，
# 消费 stage176 visibility-not-published boundary suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE177_PACKET_TMPDIR:-/tmp/cjgui-stage177-renderer-state-write-first-slice-readiness-decision-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage177_renderer_state_write_first_slice_readiness_decision_owner.sh"
STAGE176_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage176_renderer_state_write_visibility_not_published_boundary_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE176_LOG="$TMP_DIR/stage176.log"
RESULT_PACKET="$TMP_DIR/stage177-renderer-state-write-first-slice-readiness-decision.packet"
STAGE176_SUITE_PACKET="${CJGUI_STAGE176_RENDERER_STATE_WRITE_VISIBILITY_NOT_PUBLISHED_BOUNDARY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage176"
: > "$OWNER_LOG"
: > "$STAGE176_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE176_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: syntax check failed $script" >&2
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
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage177 renderer-state write first-slice readiness decision packet: owner probe failed" >&2
  echo "cjgui stage177 renderer-state write first-slice readiness decision packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage177_renderer_state_write_first_slice_readiness_decision_owner_present=true" \
  "stage176_visibility_not_published_boundary_required=true" \
  "renderer_state_write_first_slice_readiness_decision_ledger_materialized=true" \
  "commit_dry_run_rollback_visibility_predicates_bound=true" \
  "production_truth_semantic_backend_stop_line_bound=true" \
  "stage178_renderer_state_write_guarded_mutation_runtime_bridge_input_prepared=true" \
  "renderer_state_write_first_slice_candidate_ready=true" \
  "missing_runtime_predicates_materialized=true" \
  "renderer_state_write_first_slice_decision_denied=true" \
  "renderer_state_write_first_slice_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage176_input_mode="generated_stage176_suite_packet"
if [[ -n "$STAGE176_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE176_SUITE_PACKET" ]]; then
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: provided stage176 suite packet missing $STAGE176_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage176_suite_packet_used=true" > "$STAGE176_LOG"
  stage176_input_mode="provided_stage176_suite_packet"
else
  if ! env CJGUI_STAGE176_TMPDIR="$TMP_DIR/stage176" zsh "$STAGE176_SUITE_SCRIPT" > "$STAGE176_LOG" 2>&1; then
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: stage176 suite failed" >&2
    echo "cjgui stage177 renderer-state write first-slice readiness decision packet: log=$STAGE176_LOG" >&2
    exit 8
  fi
  STAGE176_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE176_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE176_SUITE_PACKET" || ! -f "$STAGE176_SUITE_PACKET" ]]; then
  echo "cjgui stage177 renderer-state write first-slice readiness decision packet: missing stage176 suite packet" >&2
  exit 9
fi
for fact in \
  "stage176_renderer_state_write_visibility_not_published_boundary_suite_passed=true" \
  "renderer_state_write_visibility_not_published_boundary_ready=true" \
  "renderer_state_write_visibility_not_published_boundary_source_ready=true" \
  "renderer_state_write_visibility_not_published_boundary_runtime_admitted=false" \
  "stage177_renderer_state_write_first_slice_readiness_decision_input_prepared=true" \
  "visibility_publication_internal_only=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE176_SUITE_PACKET" "$fact"
done

stage176_route="$(fact_value "$STAGE176_SUITE_PACKET" "renderer_state_write_visibility_not_published_boundary_route_classification")"
stage176_runtime_admitted="$(fact_value "$STAGE176_SUITE_PACKET" "renderer_state_write_visibility_not_published_boundary_runtime_admitted")"
stage176_runtime_admitted="${stage176_runtime_admitted:-false}"
decision_route="renderer_state_write_first_slice_readiness_decision_ready_runtime_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage177 renderer-state write first-slice readiness decision packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage177_renderer_state_write_first_slice_readiness_decision_packet_version=1"
  echo "stage176_input_mode=$stage176_input_mode"
  echo "stage176_suite_packet=$STAGE176_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage176_log=$STAGE176_LOG"
  echo "stage176_visibility_not_published_boundary_consumed=true"
  echo "stage176_visibility_not_published_boundary_route_classification=$stage176_route"
  echo "stage176_visibility_not_published_boundary_runtime_admitted=$stage176_runtime_admitted"
  echo "renderer_state_write_first_slice_readiness_decision_route_classification=$decision_route"
  echo "renderer_state_write_first_slice_readiness_decision_ready=true"
  echo "renderer_state_write_first_slice_source_ready=true"
  echo "renderer_state_write_first_slice_runtime_admitted=false"
  echo "renderer_state_write_first_slice_readiness_decision_ledger_materialized=true"
  echo "commit_dry_run_rollback_visibility_predicates_bound=true"
  echo "production_truth_semantic_backend_stop_line_bound=true"
  echo "renderer_state_write_first_slice_candidate_ready=true"
  echo "missing_runtime_predicates_materialized=true"
  echo "missing_runtime_predicates=production_render_truth,backend_ready_truth,semantic_runtime_admission,visibility_publication_admitted,result_envelope_promotion_token"
  echo "stage178_renderer_state_write_guarded_mutation_runtime_bridge_input_prepared=true"
  echo "renderer_state_write_first_slice_decision_denied=true"
  echo "visibility_published=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage178_renderer_state_write_guarded_mutation_runtime_bridge_after_readiness_decision"
  echo "stage177_renderer_state_write_first_slice_readiness_decision_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage177 renderer-state write first-slice readiness decision packet: route_classification=$decision_route"
echo "cjgui stage177 renderer-state write first-slice readiness decision packet: renderer_state_write_first_slice_readiness_decision_packet_path=$RESULT_PACKET"
echo "cjgui stage177 renderer-state write first-slice readiness decision packet: renderer_state_write=false"
