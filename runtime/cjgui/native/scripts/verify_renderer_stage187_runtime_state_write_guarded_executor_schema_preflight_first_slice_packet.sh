#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage187 runtime_state write guarded executor
# schema preflight packet，消费 stage186 mutation request suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE187_PACKET_TMPDIR:-/tmp/cjgui-stage187-runtime-state-guarded-executor-schema-preflight-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage187_runtime_state_write_guarded_executor_schema_preflight_first_slice_owner.sh"
STAGE186_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE186_LOG="$TMP_DIR/stage186.log"
RESULT_PACKET="$TMP_DIR/stage187-runtime-state-write-guarded-executor-schema-preflight-first-slice.packet"
STAGE186_SUITE_PACKET="${CJGUI_STAGE186_RUNTIME_STATE_WRITE_MUTATION_REQUEST_SCHEMA_ADAPTER_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage186"
: > "$OWNER_LOG"
: > "$STAGE186_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE186_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: syntax check failed $script" >&2
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
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage187 runtime_state guarded executor schema preflight packet: owner probe failed" >&2
  echo "cjgui stage187 runtime_state guarded executor schema preflight packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage187_runtime_state_guarded_executor_schema_preflight_owner_present=true" \
  "stage186_runtime_state_mutation_request_schema_adapter_required=true" \
  "runtime_state_write_guarded_executor_schema_preflight_materialized=true" \
  "mutation_request_payload_to_guarded_executor_bound=true" \
  "runtime_state_write_guarded_executor_predicate_recheck_materialized=true" \
  "rollback_visibility_hold_to_schema_preflight_bound=true" \
  "stage188_runtime_state_write_visibility_publication_schema_bridge_input_prepared=true" \
  "runtime_state_write_guarded_executor_preflight_non_mutating=true" \
  "guarded_executor_schema_preflight_predicates_satisfied=false" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage186_input_mode="generated_stage186_suite_packet"
if [[ -n "$STAGE186_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE186_SUITE_PACKET" ]]; then
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: provided stage186 suite packet missing $STAGE186_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage186_suite_packet_used=true" > "$STAGE186_LOG"
  stage186_input_mode="provided_stage186_suite_packet"
else
  if ! env CJGUI_STAGE186_TMPDIR="$TMP_DIR/stage186" zsh "$STAGE186_SUITE_SCRIPT" > "$STAGE186_LOG" 2>&1; then
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: stage186 suite failed" >&2
    echo "cjgui stage187 runtime_state guarded executor schema preflight packet: log=$STAGE186_LOG" >&2
    exit 8
  fi
  STAGE186_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE186_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE186_SUITE_PACKET" || ! -f "$STAGE186_SUITE_PACKET" ]]; then
  echo "cjgui stage187 runtime_state guarded executor schema preflight packet: missing stage186 suite packet" >&2
  exit 9
fi
for fact in \
  "stage186_runtime_state_mutation_request_schema_adapter_suite_passed=true" \
  "runtime_state_write_mutation_request_schema_adapter_ready=true" \
  "runtime_state_write_mutation_request_dry_run_payload_materialized=true" \
  "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true" \
  "renderer_state_write_eligibility=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE186_SUITE_PACKET" "$fact"
done

stage186_route="$(fact_value "$STAGE186_SUITE_PACKET" "runtime_state_write_mutation_request_schema_adapter_route_classification")"
stage187_route="runtime_state_write_guarded_executor_schema_preflight_ready_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage187 runtime_state guarded executor schema preflight packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage187_runtime_state_guarded_executor_schema_preflight_packet_version=1"
  echo "stage186_input_mode=$stage186_input_mode"
  echo "stage186_suite_packet=$STAGE186_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage186_log=$STAGE186_LOG"
  echo "stage186_runtime_state_mutation_request_schema_adapter_consumed=true"
  echo "stage186_runtime_state_mutation_request_schema_adapter_route_classification=$stage186_route"
  echo "runtime_state_write_guarded_executor_schema_preflight_route_classification=$stage187_route"
  echo "runtime_state_write_guarded_executor_schema_preflight_ready=true"
  echo "runtime_state_write_guarded_executor_schema_preflight_source_ready=true"
  echo "runtime_state_write_guarded_executor_schema_preflight_runtime_admitted=false"
  echo "runtime_state_write_guarded_executor_schema_preflight_materialized=true"
  echo "mutation_request_payload_to_guarded_executor_bound=true"
  echo "runtime_state_write_guarded_executor_predicate_recheck_materialized=true"
  echo "guarded_executor_schema_preflight_predicates_satisfied=false"
  echo "rollback_visibility_hold_to_schema_preflight_bound=true"
  echo "runtime_state_write_guarded_executor_preflight_non_mutating=true"
  echo "renderer_state_write_eligibility=false"
  echo "stage188_runtime_state_write_visibility_publication_schema_bridge_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage188_runtime_state_write_visibility_publication_schema_bridge_after_guarded_executor"
  echo "stage187_runtime_state_guarded_executor_schema_preflight_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage187 runtime_state guarded executor schema preflight packet: route_classification=$stage187_route"
echo "cjgui stage187 runtime_state guarded executor schema preflight packet: guarded_executor_schema_preflight_packet_path=$RESULT_PACKET"
echo "cjgui stage187 runtime_state guarded executor schema preflight packet: runtime_state_write=false"
