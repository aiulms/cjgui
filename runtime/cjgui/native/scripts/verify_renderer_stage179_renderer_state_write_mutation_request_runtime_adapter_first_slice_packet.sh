#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage179 mutation request runtime adapter packet，
# 消费 stage178 guarded mutation runtime bridge suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE179_PACKET_TMPDIR:-/tmp/cjgui-stage179-mutation-request-runtime-adapter-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage179_renderer_state_write_mutation_request_runtime_adapter_first_slice_owner.sh"
STAGE178_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage178_guarded_mutation_runtime_bridge_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE178_LOG="$TMP_DIR/stage178.log"
RESULT_PACKET="$TMP_DIR/stage179-renderer-state-write-mutation-request-runtime-adapter-first-slice.packet"
STAGE178_SUITE_PACKET="${CJGUI_STAGE178_GUARDED_MUTATION_RUNTIME_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage178"
: > "$OWNER_LOG"
: > "$STAGE178_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE178_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage179 mutation request runtime adapter packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage179 mutation request runtime adapter packet: syntax check failed $script" >&2
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
    echo "cjgui stage179 mutation request runtime adapter packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage179 mutation request runtime adapter packet: owner probe failed" >&2
  echo "cjgui stage179 mutation request runtime adapter packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage179_renderer_state_write_mutation_request_runtime_adapter_owner_present=true" \
  "stage178_guarded_mutation_runtime_bridge_required=true" \
  "renderer_state_write_mutation_request_runtime_adapter_materialized=true" \
  "guarded_mutation_bridge_to_mutation_request_bound=true" \
  "mutation_request_dry_run_payload_materialized=true" \
  "result_envelope_promotion_token_denial_bound=true" \
  "stage180_guarded_executor_runtime_preflight_input_prepared=true" \
  "mutation_request_runtime_adapter_non_mutating=true" \
  "mutation_request_runtime_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage178_input_mode="generated_stage178_suite_packet"
if [[ -n "$STAGE178_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE178_SUITE_PACKET" ]]; then
    echo "cjgui stage179 mutation request runtime adapter packet: provided stage178 suite packet missing $STAGE178_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage178_suite_packet_used=true" > "$STAGE178_LOG"
  stage178_input_mode="provided_stage178_suite_packet"
else
  if ! env CJGUI_STAGE178_TMPDIR="$TMP_DIR/stage178" zsh "$STAGE178_SUITE_SCRIPT" > "$STAGE178_LOG" 2>&1; then
    echo "cjgui stage179 mutation request runtime adapter packet: stage178 suite failed" >&2
    echo "cjgui stage179 mutation request runtime adapter packet: log=$STAGE178_LOG" >&2
    exit 8
  fi
  STAGE178_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE178_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE178_SUITE_PACKET" || ! -f "$STAGE178_SUITE_PACKET" ]]; then
  echo "cjgui stage179 mutation request runtime adapter packet: missing stage178 suite packet" >&2
  exit 9
fi
for fact in \
  "stage178_guarded_mutation_runtime_bridge_suite_passed=true" \
  "guarded_mutation_runtime_bridge_ready=true" \
  "guarded_mutation_runtime_bridge_source_ready=true" \
  "guarded_mutation_runtime_bridge_runtime_admitted=false" \
  "guarded_mutation_runtime_bridge_envelope_materialized=true" \
  "result_envelope_promotion_token_admitted=false" \
  "stage179_renderer_state_write_mutation_request_runtime_adapter_input_prepared=true" \
  "renderer_state_write_runtime_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE178_SUITE_PACKET" "$fact"
done

stage178_route="$(fact_value "$STAGE178_SUITE_PACKET" "guarded_mutation_runtime_bridge_route_classification")"
stage178_runtime_admitted="$(fact_value "$STAGE178_SUITE_PACKET" "guarded_mutation_runtime_bridge_runtime_admitted")"
stage178_runtime_admitted="${stage178_runtime_admitted:-false}"
adapter_route="mutation_request_runtime_adapter_ready_runtime_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage179 mutation request runtime adapter packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage179_renderer_state_write_mutation_request_runtime_adapter_packet_version=1"
  echo "stage178_input_mode=$stage178_input_mode"
  echo "stage178_suite_packet=$STAGE178_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage178_log=$STAGE178_LOG"
  echo "stage178_guarded_mutation_runtime_bridge_consumed=true"
  echo "stage178_guarded_mutation_runtime_bridge_route_classification=$stage178_route"
  echo "stage178_guarded_mutation_runtime_bridge_runtime_admitted=$stage178_runtime_admitted"
  echo "mutation_request_runtime_adapter_route_classification=$adapter_route"
  echo "mutation_request_runtime_adapter_ready=true"
  echo "mutation_request_runtime_adapter_source_ready=true"
  echo "mutation_request_runtime_adapter_runtime_admitted=false"
  echo "renderer_state_write_mutation_request_runtime_adapter_materialized=true"
  echo "guarded_mutation_bridge_to_mutation_request_bound=true"
  echo "mutation_request_dry_run_payload_materialized=true"
  echo "result_envelope_promotion_token_denial_bound=true"
  echo "mutation_request_runtime_adapter_non_mutating=true"
  echo "mutation_request_runtime_admission_denied=true"
  echo "stage180_guarded_executor_runtime_preflight_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage180_guarded_executor_runtime_preflight_after_mutation_request_adapter"
  echo "stage179_renderer_state_write_mutation_request_runtime_adapter_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage179 mutation request runtime adapter packet: route_classification=$adapter_route"
echo "cjgui stage179 mutation request runtime adapter packet: mutation_request_runtime_adapter_packet_path=$RESULT_PACKET"
echo "cjgui stage179 mutation request runtime adapter packet: renderer_state_write=false"
