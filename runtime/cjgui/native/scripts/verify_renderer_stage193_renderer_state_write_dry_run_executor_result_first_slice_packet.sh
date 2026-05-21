#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage193 dry-run executor result packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE193_PACKET_TMPDIR:-/tmp/cjgui-stage193-renderer-state-write-dry-run-executor-result-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage193_renderer_state_write_dry_run_executor_result_first_slice_owner.sh"
STAGE192_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage192_renderer_state_write_visibility_publication_positive_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE192_LOG="$TMP_DIR/stage192.log"
RESULT_PACKET="$TMP_DIR/stage193-renderer-state-write-dry-run-executor-result-first-slice.packet"
STAGE192_SUITE_PACKET="${CJGUI_STAGE192_RENDERER_STATE_WRITE_VISIBILITY_PUBLICATION_POSITIVE_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage192"
: > "$OWNER_LOG"
: > "$STAGE192_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE192_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage193 renderer_state write dry-run executor result packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage193 renderer_state write dry-run executor result packet: syntax check failed $script" >&2
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
    echo "cjgui stage193 renderer_state write dry-run executor result packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage193 renderer_state write dry-run executor result packet: owner probe failed" >&2
  echo "cjgui stage193 renderer_state write dry-run executor result packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage193_renderer_state_write_dry_run_executor_result_owner_present=true" \
  "stage192_visibility_publication_positive_dry_run_required=true" \
  "renderer_state_write_dry_run_executor_result_envelope_materialized=true" \
  "schema_fixture_mutation_rollback_visibility_receipt_bound=true" \
  "owner_local_mutation_candidate_bound_to_dry_run_executor=true" \
  "rollback_snapshot_placeholder_bound_to_dry_run_executor=true" \
  "visibility_publication_dry_run_receipt_bound_to_dry_run_executor=true" \
  "stage194_renderer_state_write_result_envelope_promotion_preflight_input_prepared=true" \
  "renderer_state_write_dry_run_executor_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage192_input_mode="generated_stage192_suite_packet"
if [[ -n "$STAGE192_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE192_SUITE_PACKET" ]]; then
    echo "cjgui stage193 renderer_state write dry-run executor result packet: provided stage192 suite packet missing $STAGE192_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage192_suite_packet_used=true" > "$STAGE192_LOG"
  stage192_input_mode="provided_stage192_suite_packet"
else
  if ! env CJGUI_STAGE192_TMPDIR="$TMP_DIR/stage192" zsh "$STAGE192_SUITE_SCRIPT" > "$STAGE192_LOG" 2>&1; then
    echo "cjgui stage193 renderer_state write dry-run executor result packet: stage192 suite failed" >&2
    echo "cjgui stage193 renderer_state write dry-run executor result packet: log=$STAGE192_LOG" >&2
    exit 8
  fi
  STAGE192_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE192_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE192_SUITE_PACKET" || ! -f "$STAGE192_SUITE_PACKET" ]]; then
  echo "cjgui stage193 renderer_state write dry-run executor result packet: missing stage192 suite packet" >&2
  exit 9
fi
for fact in \
  "stage192_renderer_state_visibility_publication_positive_dry_run_suite_passed=true" \
  "renderer_state_write_visibility_publication_positive_dry_run_ready=true" \
  "visibility_publication_dry_run_receipt_materialized=true" \
  "non_public_visibility_publication_envelope_materialized=true" \
  "fixture_visibility_publication_admitted=true" \
  "stage193_renderer_state_write_first_slice_dry_run_executor_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE192_SUITE_PACKET" "$fact"
done

stage192_route="$(fact_value "$STAGE192_SUITE_PACKET" "renderer_state_write_visibility_publication_positive_dry_run_route_classification")"
stage193_route="renderer_state_write_dry_run_executor_result_ready_non_mutating"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage193 renderer_state write dry-run executor result packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage193_renderer_state_write_dry_run_executor_result_packet_version=1"
  echo "stage192_input_mode=$stage192_input_mode"
  echo "stage192_suite_packet=$STAGE192_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage192_log=$STAGE192_LOG"
  echo "stage192_visibility_publication_positive_dry_run_consumed=true"
  echo "stage192_visibility_publication_positive_dry_run_route_classification=$stage192_route"
  echo "renderer_state_write_dry_run_executor_result_route_classification=$stage193_route"
  echo "renderer_state_write_dry_run_executor_result_ready=true"
  echo "renderer_state_write_dry_run_executor_result_source_ready=true"
  echo "renderer_state_write_dry_run_executor_result_runtime_admitted=false"
  echo "renderer_state_write_dry_run_executor_result_envelope_materialized=true"
  echo "schema_fixture_mutation_rollback_visibility_receipt_bound=true"
  echo "owner_local_mutation_candidate_bound_to_dry_run_executor=true"
  echo "rollback_snapshot_placeholder_bound_to_dry_run_executor=true"
  echo "visibility_publication_dry_run_receipt_bound_to_dry_run_executor=true"
  echo "stage194_renderer_state_write_result_envelope_promotion_preflight_input_prepared=true"
  echo "renderer_state_write_dry_run_executor_non_mutating=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_published=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage194_renderer_state_write_result_envelope_promotion_preflight_after_dry_run_executor_result"
  echo "stage193_renderer_state_write_dry_run_executor_result_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage193 renderer_state write dry-run executor result packet: route_classification=$stage193_route"
echo "cjgui stage193 renderer_state write dry-run executor result packet: dry_run_executor_result_packet_path=$RESULT_PACKET"
echo "cjgui stage193 renderer_state write dry-run executor result packet: renderer_state_write=false"
