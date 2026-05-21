#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage178 guarded mutation runtime bridge packet，
# 消费 stage177 readiness decision suite packet，并输出 stage179 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE178_PACKET_TMPDIR:-/tmp/cjgui-stage178-guarded-mutation-runtime-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage178_guarded_mutation_runtime_bridge_first_slice_owner.sh"
STAGE177_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage177_renderer_state_write_first_slice_readiness_decision_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE177_LOG="$TMP_DIR/stage177.log"
RESULT_PACKET="$TMP_DIR/stage178-guarded-mutation-runtime-bridge-first-slice.packet"
STAGE177_SUITE_PACKET="${CJGUI_STAGE177_RENDERER_STATE_WRITE_FIRST_SLICE_READINESS_DECISION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage177"
: > "$OWNER_LOG"
: > "$STAGE177_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE177_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage178 guarded mutation runtime bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage178 guarded mutation runtime bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage178 guarded mutation runtime bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage178 guarded mutation runtime bridge packet: owner probe failed" >&2
  echo "cjgui stage178 guarded mutation runtime bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage178_guarded_mutation_runtime_bridge_owner_present=true" \
  "stage177_readiness_decision_required=true" \
  "guarded_mutation_runtime_bridge_envelope_materialized=true" \
  "result_envelope_promotion_token_rechecked=true" \
  "missing_runtime_predicate_ledger_bound=true" \
  "stage179_renderer_state_write_mutation_request_runtime_adapter_input_prepared=true" \
  "guarded_mutation_runtime_bridge_non_mutating=true" \
  "renderer_state_write_runtime_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage177_input_mode="generated_stage177_suite_packet"
if [[ -n "$STAGE177_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE177_SUITE_PACKET" ]]; then
    echo "cjgui stage178 guarded mutation runtime bridge packet: provided stage177 suite packet missing $STAGE177_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage177_suite_packet_used=true" > "$STAGE177_LOG"
  stage177_input_mode="provided_stage177_suite_packet"
else
  if ! env CJGUI_STAGE177_TMPDIR="$TMP_DIR/stage177" zsh "$STAGE177_SUITE_SCRIPT" > "$STAGE177_LOG" 2>&1; then
    echo "cjgui stage178 guarded mutation runtime bridge packet: stage177 suite failed" >&2
    echo "cjgui stage178 guarded mutation runtime bridge packet: log=$STAGE177_LOG" >&2
    exit 8
  fi
  STAGE177_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE177_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE177_SUITE_PACKET" || ! -f "$STAGE177_SUITE_PACKET" ]]; then
  echo "cjgui stage178 guarded mutation runtime bridge packet: missing stage177 suite packet" >&2
  exit 9
fi
for fact in \
  "stage177_renderer_state_write_first_slice_readiness_decision_suite_passed=true" \
  "renderer_state_write_first_slice_readiness_decision_ready=true" \
  "renderer_state_write_first_slice_source_ready=true" \
  "renderer_state_write_first_slice_runtime_admitted=false" \
  "stage178_renderer_state_write_guarded_mutation_runtime_bridge_input_prepared=true" \
  "renderer_state_write_first_slice_candidate_ready=true" \
  "missing_runtime_predicates_materialized=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE177_SUITE_PACKET" "$fact"
done

stage177_route="$(fact_value "$STAGE177_SUITE_PACKET" "renderer_state_write_first_slice_readiness_decision_route_classification")"
stage177_runtime_admitted="$(fact_value "$STAGE177_SUITE_PACKET" "renderer_state_write_first_slice_runtime_admitted")"
stage177_runtime_admitted="${stage177_runtime_admitted:-false}"
bridge_route="guarded_mutation_runtime_bridge_ready_runtime_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage178 guarded mutation runtime bridge packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage178_guarded_mutation_runtime_bridge_packet_version=1"
  echo "stage177_input_mode=$stage177_input_mode"
  echo "stage177_suite_packet=$STAGE177_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage177_log=$STAGE177_LOG"
  echo "stage177_readiness_decision_consumed=true"
  echo "stage177_readiness_decision_route_classification=$stage177_route"
  echo "stage177_readiness_decision_runtime_admitted=$stage177_runtime_admitted"
  echo "guarded_mutation_runtime_bridge_route_classification=$bridge_route"
  echo "guarded_mutation_runtime_bridge_ready=true"
  echo "guarded_mutation_runtime_bridge_source_ready=true"
  echo "guarded_mutation_runtime_bridge_runtime_admitted=false"
  echo "guarded_mutation_runtime_bridge_envelope_materialized=true"
  echo "result_envelope_promotion_token_rechecked=true"
  echo "result_envelope_promotion_token_admitted=false"
  echo "missing_runtime_predicate_ledger_bound=true"
  echo "guarded_mutation_runtime_bridge_non_mutating=true"
  echo "renderer_state_write_runtime_admission_denied=true"
  echo "stage179_renderer_state_write_mutation_request_runtime_adapter_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage179_renderer_state_write_mutation_request_runtime_adapter_after_guarded_mutation_bridge"
  echo "stage178_guarded_mutation_runtime_bridge_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage178 guarded mutation runtime bridge packet: route_classification=$bridge_route"
echo "cjgui stage178 guarded mutation runtime bridge packet: guarded_mutation_runtime_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage178 guarded mutation runtime bridge packet: renderer_state_write=false"
