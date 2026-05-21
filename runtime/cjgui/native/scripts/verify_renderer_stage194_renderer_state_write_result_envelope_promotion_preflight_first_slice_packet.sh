#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage194 result-envelope promotion preflight packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE194_PACKET_TMPDIR:-/tmp/cjgui-stage194-renderer-state-write-result-envelope-promotion-preflight-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage194_renderer_state_write_result_envelope_promotion_preflight_first_slice_owner.sh"
STAGE193_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage193_renderer_state_write_dry_run_executor_result_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE193_LOG="$TMP_DIR/stage193.log"
RESULT_PACKET="$TMP_DIR/stage194-renderer-state-write-result-envelope-promotion-preflight-first-slice.packet"
STAGE193_SUITE_PACKET="${CJGUI_STAGE193_RENDERER_STATE_WRITE_DRY_RUN_EXECUTOR_RESULT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage193"
: > "$OWNER_LOG"
: > "$STAGE193_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE193_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: syntax check failed $script" >&2
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
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: owner probe failed" >&2
  echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage194_renderer_state_write_result_envelope_promotion_preflight_owner_present=true" \
  "stage193_dry_run_executor_result_required=true" \
  "renderer_state_write_result_envelope_promotion_preflight_materialized=true" \
  "dry_run_executor_result_envelope_bound_to_promotion_preflight=true" \
  "result_envelope_promotion_token_candidate_ledger_materialized=true" \
  "missing_production_predicate_ledger_materialized=true" \
  "stage195_renderer_state_write_admission_join_decision_input_prepared=true" \
  "result_envelope_promotion_preflight_non_production=true" \
  "result_envelope_promotion_token=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage193_input_mode="generated_stage193_suite_packet"
if [[ -n "$STAGE193_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE193_SUITE_PACKET" ]]; then
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: provided stage193 suite packet missing $STAGE193_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage193_suite_packet_used=true" > "$STAGE193_LOG"
  stage193_input_mode="provided_stage193_suite_packet"
else
  if ! env CJGUI_STAGE193_TMPDIR="$TMP_DIR/stage193" zsh "$STAGE193_SUITE_SCRIPT" > "$STAGE193_LOG" 2>&1; then
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: stage193 suite failed" >&2
    echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: log=$STAGE193_LOG" >&2
    exit 8
  fi
  STAGE193_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE193_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE193_SUITE_PACKET" || ! -f "$STAGE193_SUITE_PACKET" ]]; then
  echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: missing stage193 suite packet" >&2
  exit 9
fi
for fact in \
  "stage193_renderer_state_write_dry_run_executor_result_suite_passed=true" \
  "renderer_state_write_dry_run_executor_result_ready=true" \
  "renderer_state_write_dry_run_executor_result_envelope_materialized=true" \
  "schema_fixture_mutation_rollback_visibility_receipt_bound=true" \
  "stage194_renderer_state_write_result_envelope_promotion_preflight_input_prepared=true" \
  "renderer_state_write_dry_run_executor_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE193_SUITE_PACKET" "$fact"
done

stage193_route="$(fact_value "$STAGE193_SUITE_PACKET" "renderer_state_write_dry_run_executor_result_route_classification")"
stage194_route="renderer_state_write_result_envelope_promotion_preflight_ready_token_candidate_only"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage194_renderer_state_write_result_envelope_promotion_preflight_packet_version=1"
  echo "stage193_input_mode=$stage193_input_mode"
  echo "stage193_suite_packet=$STAGE193_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage193_log=$STAGE193_LOG"
  echo "stage193_dry_run_executor_result_consumed=true"
  echo "stage193_dry_run_executor_result_route_classification=$stage193_route"
  echo "renderer_state_write_result_envelope_promotion_preflight_route_classification=$stage194_route"
  echo "renderer_state_write_result_envelope_promotion_preflight_ready=true"
  echo "renderer_state_write_result_envelope_promotion_preflight_source_ready=true"
  echo "renderer_state_write_result_envelope_promotion_preflight_runtime_admitted=false"
  echo "renderer_state_write_result_envelope_promotion_preflight_materialized=true"
  echo "dry_run_executor_result_envelope_bound_to_promotion_preflight=true"
  echo "result_envelope_promotion_token_candidate_ledger_materialized=true"
  echo "missing_production_predicate_ledger_materialized=true"
  echo "stage195_renderer_state_write_admission_join_decision_input_prepared=true"
  echo "result_envelope_promotion_preflight_non_production=true"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage195_renderer_state_write_admission_join_decision_after_result_envelope_promotion_preflight"
  echo "stage194_renderer_state_write_result_envelope_promotion_preflight_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: route_classification=$stage194_route"
echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: result_envelope_promotion_preflight_packet_path=$RESULT_PACKET"
echo "cjgui stage194 renderer_state write result-envelope promotion preflight packet: renderer_state_write=false"
