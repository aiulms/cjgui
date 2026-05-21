#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage167 first-slice contract packet，消费 stage166
# decision recheck suite packet，并输出 stage168 admission snapshot 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE167_PACKET_TMPDIR:-/tmp/cjgui-stage167-renderer-state-write-first-slice-contract-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage167_renderer_state_write_first_slice_contract_owner.sh"
STAGE166_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage166_renderer_state_write_decision_recheck_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE166_LOG="$TMP_DIR/stage166.log"
RESULT_PACKET="$TMP_DIR/stage167-renderer-state-write-first-slice-contract.packet"
STAGE166_SUITE_PACKET="${CJGUI_STAGE166_RENDERER_STATE_WRITE_DECISION_RECHECK_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage166"
: > "$OWNER_LOG"
: > "$STAGE166_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE166_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage167 renderer-state write first-slice contract packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage167 renderer-state write first-slice contract packet: syntax check failed $script" >&2
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
    echo "cjgui stage167 renderer-state write first-slice contract packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage167 renderer-state write first-slice contract packet: owner probe failed" >&2
  echo "cjgui stage167 renderer-state write first-slice contract packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage167_renderer_state_write_first_slice_contract_owner_present=true" \
  "stage166_renderer_state_write_decision_recheck_required=true" \
  "renderer_state_write_first_slice_contract_materialized=true" \
  "owner_local_state_envelope_contract_bound=true" \
  "stage168_renderer_state_write_admission_snapshot_input_prepared=true" \
  "renderer_state_write_first_slice_contract_ready=true" \
  "renderer_state_write_first_slice_contract_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage166_input_mode="generated_stage166_suite_packet"
if [[ -n "$STAGE166_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE166_SUITE_PACKET" ]]; then
    echo "cjgui stage167 renderer-state write first-slice contract packet: provided stage166 suite packet missing $STAGE166_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage166_suite_packet_used=true" > "$STAGE166_LOG"
  stage166_input_mode="provided_stage166_suite_packet"
else
  if ! env CJGUI_STAGE166_TMPDIR="$TMP_DIR/stage166" zsh "$STAGE166_SUITE_SCRIPT" > "$STAGE166_LOG" 2>&1; then
    echo "cjgui stage167 renderer-state write first-slice contract packet: stage166 suite failed" >&2
    echo "cjgui stage167 renderer-state write first-slice contract packet: log=$STAGE166_LOG" >&2
    exit 8
  fi
  STAGE166_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE166_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE166_SUITE_PACKET" || ! -f "$STAGE166_SUITE_PACKET" ]]; then
  echo "cjgui stage167 renderer-state write first-slice contract packet: missing stage166 suite packet" >&2
  exit 9
fi
for fact in \
  "stage166_renderer_state_write_decision_recheck_suite_passed=true" \
  "renderer_state_write_decision_recheck_ready=true" \
  "renderer_state_write_decision_recheck_source_ready=true" \
  "renderer_state_write_decision_recheck_runtime_admitted=false" \
  "renderer_state_write_first_slice_contract_input_prepared=true" \
  "renderer_state_write_decision_denied=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE166_SUITE_PACKET" "$fact"
done

stage166_route="$(fact_value "$STAGE166_SUITE_PACKET" "renderer_state_write_decision_recheck_route_classification")"
stage166_runtime_admitted="$(fact_value "$STAGE166_SUITE_PACKET" "renderer_state_write_decision_recheck_runtime_admitted")"
stage166_runtime_admitted="${stage166_runtime_admitted:-false}"
contract_route="renderer_state_write_first_slice_contract_blocked_stage166_decision_recheck_admission"
if [[ "$stage166_route" == *"host_metal_device_unavailable" ]]; then
  contract_route="renderer_state_write_first_slice_contract_blocked_host_metal_device_unavailable"
elif [[ "$stage166_runtime_admitted" == "true" ]]; then
  contract_route="renderer_state_write_first_slice_contract_ready_for_admission_snapshot"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage167 renderer-state write first-slice contract packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage167_renderer_state_write_first_slice_contract_packet_version=1"
  echo "stage166_input_mode=$stage166_input_mode"
  echo "stage166_suite_packet=$STAGE166_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage166_log=$STAGE166_LOG"
  echo "stage166_renderer_state_write_decision_recheck_consumed=true"
  echo "stage166_renderer_state_write_decision_recheck_route_classification=$stage166_route"
  echo "stage166_renderer_state_write_decision_recheck_runtime_admitted=$stage166_runtime_admitted"
  echo "renderer_state_write_first_slice_contract_route_classification=$contract_route"
  echo "renderer_state_write_first_slice_contract_ready=true"
  echo "renderer_state_write_first_slice_contract_source_ready=true"
  echo "renderer_state_write_first_slice_contract_runtime_admitted=false"
  echo "renderer_state_write_first_slice_contract_materialized=true"
  echo "owner_local_state_envelope_contract_bound=true"
  echo "mutation_request_contract_bound=true"
  echo "guarded_executor_contract_bound=true"
  echo "visibility_publication_contract_bound=true"
  echo "rollback_contract_bound=true"
  echo "stage168_renderer_state_write_admission_snapshot_input_prepared=true"
  echo "renderer_state_write_first_slice_contract_non_mutating=true"
  echo "renderer_state_write_first_slice_contract_predicates_satisfied=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage168_renderer_state_write_admission_snapshot_after_first_slice_contract"
  echo "stage167_renderer_state_write_first_slice_contract_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage167 renderer-state write first-slice contract packet: route_classification=$contract_route"
echo "cjgui stage167 renderer-state write first-slice contract packet: renderer_state_write_first_slice_contract_packet_path=$RESULT_PACKET"
echo "cjgui stage167 renderer-state write first-slice contract packet: renderer_state_write=false"
