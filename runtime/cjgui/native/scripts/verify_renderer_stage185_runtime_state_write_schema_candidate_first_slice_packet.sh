#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage185 runtime_state write schema candidate
# packet，消费 stage184 owner-local state envelope suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE185_PACKET_TMPDIR:-/tmp/cjgui-stage185-runtime-state-schema-candidate-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage185_runtime_state_write_schema_candidate_first_slice_owner.sh"
STAGE184_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage184_renderer_state_write_owner_local_state_envelope_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE184_LOG="$TMP_DIR/stage184.log"
RESULT_PACKET="$TMP_DIR/stage185-runtime-state-write-schema-candidate-first-slice.packet"
STAGE184_SUITE_PACKET="${CJGUI_STAGE184_OWNER_LOCAL_STATE_ENVELOPE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage184"
: > "$OWNER_LOG"
: > "$STAGE184_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE184_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage185 runtime_state schema candidate packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage185 runtime_state schema candidate packet: syntax check failed $script" >&2
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
    echo "cjgui stage185 runtime_state schema candidate packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage185 runtime_state schema candidate packet: owner probe failed" >&2
  echo "cjgui stage185 runtime_state schema candidate packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage185_runtime_state_schema_candidate_owner_present=true" \
  "stage184_owner_local_state_envelope_required=true" \
  "runtime_state_write_schema_candidate_materialized=true" \
  "owner_local_state_envelope_to_schema_candidate_bound=true" \
  "blocked_write_decision_to_schema_candidate_bound=true" \
  "runtime_state_write_stop_line_to_schema_candidate_bound=true" \
  "stage186_runtime_state_write_mutation_request_schema_adapter_input_prepared=true" \
  "runtime_state_write_schema_candidate_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage184_input_mode="generated_stage184_suite_packet"
if [[ -n "$STAGE184_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE184_SUITE_PACKET" ]]; then
    echo "cjgui stage185 runtime_state schema candidate packet: provided stage184 suite packet missing $STAGE184_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage184_suite_packet_used=true" > "$STAGE184_LOG"
  stage184_input_mode="provided_stage184_suite_packet"
else
  if ! env CJGUI_STAGE184_TMPDIR="$TMP_DIR/stage184" zsh "$STAGE184_SUITE_SCRIPT" > "$STAGE184_LOG" 2>&1; then
    echo "cjgui stage185 runtime_state schema candidate packet: stage184 suite failed" >&2
    echo "cjgui stage185 runtime_state schema candidate packet: log=$STAGE184_LOG" >&2
    exit 8
  fi
  STAGE184_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE184_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE184_SUITE_PACKET" || ! -f "$STAGE184_SUITE_PACKET" ]]; then
  echo "cjgui stage185 runtime_state schema candidate packet: missing stage184 suite packet" >&2
  exit 9
fi
for fact in \
  "stage184_owner_local_state_envelope_suite_passed=true" \
  "renderer_state_write_owner_local_state_envelope_ready=true" \
  "renderer_state_write_owner_local_state_envelope_materialized=true" \
  "stage185_runtime_state_write_schema_candidate_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE184_SUITE_PACKET" "$fact"
done

stage184_route="$(fact_value "$STAGE184_SUITE_PACKET" "renderer_state_write_owner_local_state_envelope_route_classification")"
stage185_route="runtime_state_write_schema_candidate_ready_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage185 runtime_state schema candidate packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage185_runtime_state_schema_candidate_packet_version=1"
  echo "stage184_input_mode=$stage184_input_mode"
  echo "stage184_suite_packet=$STAGE184_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage184_log=$STAGE184_LOG"
  echo "stage184_owner_local_state_envelope_consumed=true"
  echo "stage184_owner_local_state_envelope_route_classification=$stage184_route"
  echo "runtime_state_write_schema_candidate_route_classification=$stage185_route"
  echo "runtime_state_write_schema_candidate_ready=true"
  echo "runtime_state_write_schema_candidate_source_ready=true"
  echo "runtime_state_write_schema_candidate_runtime_admitted=false"
  echo "runtime_state_write_schema_candidate_ledger_materialized=true"
  echo "owner_local_state_envelope_to_schema_candidate_bound=true"
  echo "blocked_write_decision_to_schema_candidate_bound=true"
  echo "runtime_state_write_stop_line_to_schema_candidate_bound=true"
  echo "runtime_state_write_schema_candidate_dry_run_only=true"
  echo "renderer_state_write_eligibility=false"
  echo "stage186_runtime_state_write_mutation_request_schema_adapter_input_prepared=true"
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
  echo "next_route=stage186_runtime_state_write_mutation_request_schema_adapter_after_schema_candidate"
  echo "stage185_runtime_state_schema_candidate_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage185 runtime_state schema candidate packet: route_classification=$stage185_route"
echo "cjgui stage185 runtime_state schema candidate packet: schema_candidate_packet_path=$RESULT_PACKET"
echo "cjgui stage185 runtime_state schema candidate packet: runtime_state_write=false"
