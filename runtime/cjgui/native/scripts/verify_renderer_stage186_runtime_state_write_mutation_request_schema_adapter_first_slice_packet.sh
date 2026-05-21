#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage186 runtime_state write mutation request
# schema adapter packet，消费 stage185 schema candidate suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE186_PACKET_TMPDIR:-/tmp/cjgui-stage186-runtime-state-mutation-request-schema-adapter-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice_owner.sh"
STAGE185_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage185_runtime_state_write_schema_candidate_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE185_LOG="$TMP_DIR/stage185.log"
RESULT_PACKET="$TMP_DIR/stage186-runtime-state-write-mutation-request-schema-adapter-first-slice.packet"
STAGE185_SUITE_PACKET="${CJGUI_STAGE185_RUNTIME_STATE_WRITE_SCHEMA_CANDIDATE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage185"
: > "$OWNER_LOG"
: > "$STAGE185_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE185_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: syntax check failed $script" >&2
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
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter packet: owner probe failed" >&2
  echo "cjgui stage186 runtime_state mutation request schema adapter packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage186_runtime_state_mutation_request_schema_adapter_owner_present=true" \
  "stage185_runtime_state_schema_candidate_required=true" \
  "runtime_state_write_mutation_request_schema_adapter_materialized=true" \
  "schema_candidate_to_mutation_request_bound=true" \
  "runtime_state_write_mutation_request_dry_run_payload_materialized=true" \
  "runtime_state_write_admission_denial_to_mutation_request_bound=true" \
  "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true" \
  "runtime_state_write_mutation_request_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage185_input_mode="generated_stage185_suite_packet"
if [[ -n "$STAGE185_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE185_SUITE_PACKET" ]]; then
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: provided stage185 suite packet missing $STAGE185_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage185_suite_packet_used=true" > "$STAGE185_LOG"
  stage185_input_mode="provided_stage185_suite_packet"
else
  if ! env CJGUI_STAGE185_TMPDIR="$TMP_DIR/stage185" zsh "$STAGE185_SUITE_SCRIPT" > "$STAGE185_LOG" 2>&1; then
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: stage185 suite failed" >&2
    echo "cjgui stage186 runtime_state mutation request schema adapter packet: log=$STAGE185_LOG" >&2
    exit 8
  fi
  STAGE185_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE185_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE185_SUITE_PACKET" || ! -f "$STAGE185_SUITE_PACKET" ]]; then
  echo "cjgui stage186 runtime_state mutation request schema adapter packet: missing stage185 suite packet" >&2
  exit 9
fi
for fact in \
  "stage185_runtime_state_schema_candidate_suite_passed=true" \
  "runtime_state_write_schema_candidate_ready=true" \
  "runtime_state_write_schema_candidate_ledger_materialized=true" \
  "stage186_runtime_state_write_mutation_request_schema_adapter_input_prepared=true" \
  "runtime_state_write_schema_candidate_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE185_SUITE_PACKET" "$fact"
done

stage185_route="$(fact_value "$STAGE185_SUITE_PACKET" "runtime_state_write_schema_candidate_route_classification")"
stage186_route="runtime_state_write_mutation_request_schema_adapter_ready_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage186_runtime_state_mutation_request_schema_adapter_packet_version=1"
  echo "stage185_input_mode=$stage185_input_mode"
  echo "stage185_suite_packet=$STAGE185_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage185_log=$STAGE185_LOG"
  echo "stage185_runtime_state_schema_candidate_consumed=true"
  echo "stage185_runtime_state_schema_candidate_route_classification=$stage185_route"
  echo "runtime_state_write_mutation_request_schema_adapter_route_classification=$stage186_route"
  echo "runtime_state_write_mutation_request_schema_adapter_ready=true"
  echo "runtime_state_write_mutation_request_schema_adapter_source_ready=true"
  echo "runtime_state_write_mutation_request_schema_adapter_runtime_admitted=false"
  echo "runtime_state_write_mutation_request_schema_adapter_materialized=true"
  echo "schema_candidate_to_mutation_request_bound=true"
  echo "runtime_state_write_mutation_request_dry_run_payload_materialized=true"
  echo "runtime_state_write_admission_denial_to_mutation_request_bound=true"
  echo "runtime_state_write_mutation_request_dry_run_only=true"
  echo "renderer_state_write_eligibility=false"
  echo "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true"
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
  echo "next_route=stage187_runtime_state_write_guarded_executor_schema_preflight_after_mutation_request"
  echo "stage186_runtime_state_mutation_request_schema_adapter_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage186 runtime_state mutation request schema adapter packet: route_classification=$stage186_route"
echo "cjgui stage186 runtime_state mutation request schema adapter packet: mutation_request_schema_adapter_packet_path=$RESULT_PACKET"
echo "cjgui stage186 runtime_state mutation request schema adapter packet: runtime_state_write=false"
