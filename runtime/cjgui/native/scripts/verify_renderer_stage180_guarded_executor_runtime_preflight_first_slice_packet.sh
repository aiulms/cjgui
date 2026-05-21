#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage180 guarded executor runtime preflight packet，
# 消费 stage179 mutation request runtime adapter suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE180_PACKET_TMPDIR:-/tmp/cjgui-stage180-guarded-executor-runtime-preflight-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage180_guarded_executor_runtime_preflight_first_slice_owner.sh"
STAGE179_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage179_renderer_state_write_mutation_request_runtime_adapter_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE179_LOG="$TMP_DIR/stage179.log"
RESULT_PACKET="$TMP_DIR/stage180-guarded-executor-runtime-preflight-first-slice.packet"
STAGE179_SUITE_PACKET="${CJGUI_STAGE179_RENDERER_STATE_WRITE_MUTATION_REQUEST_RUNTIME_ADAPTER_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage179"
: > "$OWNER_LOG"
: > "$STAGE179_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE179_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage180 guarded executor runtime preflight packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage180 guarded executor runtime preflight packet: syntax check failed $script" >&2
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
    echo "cjgui stage180 guarded executor runtime preflight packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage180 guarded executor runtime preflight packet: owner probe failed" >&2
  echo "cjgui stage180 guarded executor runtime preflight packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage180_guarded_executor_runtime_preflight_owner_present=true" \
  "stage179_mutation_request_runtime_adapter_required=true" \
  "guarded_executor_runtime_preflight_envelope_materialized=true" \
  "mutation_request_payload_to_guarded_executor_bound=true" \
  "guarded_executor_predicate_recheck_materialized=true" \
  "rollback_visibility_hold_bound=true" \
  "stage181_visibility_publication_readiness_bridge_input_prepared=true" \
  "guarded_executor_runtime_preflight_non_mutating=true" \
  "guarded_executor_runtime_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage179_input_mode="generated_stage179_suite_packet"
if [[ -n "$STAGE179_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE179_SUITE_PACKET" ]]; then
    echo "cjgui stage180 guarded executor runtime preflight packet: provided stage179 suite packet missing $STAGE179_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage179_suite_packet_used=true" > "$STAGE179_LOG"
  stage179_input_mode="provided_stage179_suite_packet"
else
  if ! env CJGUI_STAGE179_TMPDIR="$TMP_DIR/stage179" zsh "$STAGE179_SUITE_SCRIPT" > "$STAGE179_LOG" 2>&1; then
    echo "cjgui stage180 guarded executor runtime preflight packet: stage179 suite failed" >&2
    echo "cjgui stage180 guarded executor runtime preflight packet: log=$STAGE179_LOG" >&2
    exit 8
  fi
  STAGE179_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE179_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE179_SUITE_PACKET" || ! -f "$STAGE179_SUITE_PACKET" ]]; then
  echo "cjgui stage180 guarded executor runtime preflight packet: missing stage179 suite packet" >&2
  exit 9
fi
for fact in \
  "stage179_renderer_state_write_mutation_request_runtime_adapter_suite_passed=true" \
  "mutation_request_runtime_adapter_ready=true" \
  "mutation_request_runtime_adapter_source_ready=true" \
  "mutation_request_runtime_adapter_runtime_admitted=false" \
  "mutation_request_dry_run_payload_materialized=true" \
  "stage180_guarded_executor_runtime_preflight_input_prepared=true" \
  "mutation_request_runtime_admission_denied=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE179_SUITE_PACKET" "$fact"
done

stage179_route="$(fact_value "$STAGE179_SUITE_PACKET" "mutation_request_runtime_adapter_route_classification")"
stage179_runtime_admitted="$(fact_value "$STAGE179_SUITE_PACKET" "mutation_request_runtime_adapter_runtime_admitted")"
stage179_runtime_admitted="${stage179_runtime_admitted:-false}"
preflight_route="guarded_executor_runtime_preflight_ready_runtime_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage180 guarded executor runtime preflight packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage180_guarded_executor_runtime_preflight_packet_version=1"
  echo "stage179_input_mode=$stage179_input_mode"
  echo "stage179_suite_packet=$STAGE179_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage179_log=$STAGE179_LOG"
  echo "stage179_mutation_request_runtime_adapter_consumed=true"
  echo "stage179_mutation_request_runtime_adapter_route_classification=$stage179_route"
  echo "stage179_mutation_request_runtime_adapter_runtime_admitted=$stage179_runtime_admitted"
  echo "guarded_executor_runtime_preflight_route_classification=$preflight_route"
  echo "guarded_executor_runtime_preflight_ready=true"
  echo "guarded_executor_runtime_preflight_source_ready=true"
  echo "guarded_executor_runtime_preflight_runtime_admitted=false"
  echo "guarded_executor_runtime_preflight_envelope_materialized=true"
  echo "mutation_request_payload_to_guarded_executor_bound=true"
  echo "guarded_executor_predicate_recheck_materialized=true"
  echo "guarded_executor_predicates_satisfied=false"
  echo "rollback_visibility_hold_bound=true"
  echo "stage181_visibility_publication_readiness_bridge_input_prepared=true"
  echo "guarded_executor_runtime_preflight_non_mutating=true"
  echo "guarded_executor_runtime_admission_denied=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage181_visibility_publication_readiness_bridge_after_guarded_executor_preflight"
  echo "stage180_guarded_executor_runtime_preflight_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage180 guarded executor runtime preflight packet: route_classification=$preflight_route"
echo "cjgui stage180 guarded executor runtime preflight packet: guarded_executor_runtime_preflight_packet_path=$RESULT_PACKET"
echo "cjgui stage180 guarded executor runtime preflight packet: renderer_state_write=false"
