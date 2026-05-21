#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage168 admission snapshot packet，消费 stage167
# first-slice contract suite packet，并输出 stage169 owner-local dry-run 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE168_PACKET_TMPDIR:-/tmp/cjgui-stage168-renderer-state-write-admission-snapshot-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage168_renderer_state_write_admission_snapshot_first_slice_owner.sh"
STAGE167_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage167_renderer_state_write_first_slice_contract_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE167_LOG="$TMP_DIR/stage167.log"
RESULT_PACKET="$TMP_DIR/stage168-renderer-state-write-admission-snapshot-first-slice.packet"
STAGE167_SUITE_PACKET="${CJGUI_STAGE167_RENDERER_STATE_WRITE_FIRST_SLICE_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage167"
: > "$OWNER_LOG"
: > "$STAGE167_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE167_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage168 renderer-state write admission snapshot packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage168 renderer-state write admission snapshot packet: syntax check failed $script" >&2
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
    echo "cjgui stage168 renderer-state write admission snapshot packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage168 renderer-state write admission snapshot packet: owner probe failed" >&2
  echo "cjgui stage168 renderer-state write admission snapshot packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage168_renderer_state_write_admission_snapshot_owner_present=true" \
  "stage167_renderer_state_write_first_slice_contract_required=true" \
  "renderer_state_write_admission_snapshot_ledger_materialized=true" \
  "production_truth_predicate_snapshot_bound=true" \
  "semantic_comparison_predicate_snapshot_bound=true" \
  "write_token_predicate_snapshot_bound=true" \
  "stage169_owner_local_state_envelope_dry_run_input_prepared=true" \
  "renderer_state_write_admission_snapshot_ready=true" \
  "renderer_state_write_admission_snapshot_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage167_input_mode="generated_stage167_suite_packet"
if [[ -n "$STAGE167_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE167_SUITE_PACKET" ]]; then
    echo "cjgui stage168 renderer-state write admission snapshot packet: provided stage167 suite packet missing $STAGE167_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage167_suite_packet_used=true" > "$STAGE167_LOG"
  stage167_input_mode="provided_stage167_suite_packet"
else
  if ! env CJGUI_STAGE167_TMPDIR="$TMP_DIR/stage167" zsh "$STAGE167_SUITE_SCRIPT" > "$STAGE167_LOG" 2>&1; then
    echo "cjgui stage168 renderer-state write admission snapshot packet: stage167 suite failed" >&2
    echo "cjgui stage168 renderer-state write admission snapshot packet: log=$STAGE167_LOG" >&2
    exit 8
  fi
  STAGE167_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE167_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE167_SUITE_PACKET" || ! -f "$STAGE167_SUITE_PACKET" ]]; then
  echo "cjgui stage168 renderer-state write admission snapshot packet: missing stage167 suite packet" >&2
  exit 9
fi
for fact in \
  "stage167_renderer_state_write_first_slice_contract_suite_passed=true" \
  "renderer_state_write_first_slice_contract_ready=true" \
  "renderer_state_write_first_slice_contract_source_ready=true" \
  "renderer_state_write_first_slice_contract_runtime_admitted=false" \
  "stage168_renderer_state_write_admission_snapshot_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE167_SUITE_PACKET" "$fact"
done

stage167_route="$(fact_value "$STAGE167_SUITE_PACKET" "renderer_state_write_first_slice_contract_route_classification")"
stage167_runtime_admitted="$(fact_value "$STAGE167_SUITE_PACKET" "renderer_state_write_first_slice_contract_runtime_admitted")"
stage167_runtime_admitted="${stage167_runtime_admitted:-false}"
snapshot_route="renderer_state_write_admission_snapshot_blocked_stage167_contract_admission"
if [[ "$stage167_route" == *"host_metal_device_unavailable" ]]; then
  snapshot_route="renderer_state_write_admission_snapshot_blocked_host_metal_device_unavailable"
elif [[ "$stage167_runtime_admitted" == "true" ]]; then
  snapshot_route="renderer_state_write_admission_snapshot_ready_for_owner_local_state_envelope_dry_run"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage168 renderer-state write admission snapshot packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage168_renderer_state_write_admission_snapshot_packet_version=1"
  echo "stage167_input_mode=$stage167_input_mode"
  echo "stage167_suite_packet=$STAGE167_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage167_log=$STAGE167_LOG"
  echo "stage167_renderer_state_write_first_slice_contract_consumed=true"
  echo "stage167_renderer_state_write_first_slice_contract_route_classification=$stage167_route"
  echo "stage167_renderer_state_write_first_slice_contract_runtime_admitted=$stage167_runtime_admitted"
  echo "renderer_state_write_admission_snapshot_route_classification=$snapshot_route"
  echo "renderer_state_write_admission_snapshot_ready=true"
  echo "renderer_state_write_admission_snapshot_source_ready=true"
  echo "renderer_state_write_admission_snapshot_runtime_admitted=false"
  echo "renderer_state_write_admission_snapshot_ledger_materialized=true"
  echo "production_truth_predicate_snapshot_bound=true"
  echo "semantic_comparison_predicate_snapshot_bound=true"
  echo "write_token_predicate_snapshot_bound=true"
  echo "mutation_request_predicate_snapshot_bound=true"
  echo "guarded_executor_predicate_snapshot_bound=true"
  echo "visibility_publication_predicate_snapshot_bound=true"
  echo "rollback_predicate_snapshot_bound=true"
  echo "stage169_owner_local_state_envelope_dry_run_input_prepared=true"
  echo "renderer_state_write_admission_snapshot_predicates_satisfied=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage169_renderer_state_write_owner_local_state_envelope_dry_run_after_admission_snapshot"
  echo "stage168_renderer_state_write_admission_snapshot_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage168 renderer-state write admission snapshot packet: route_classification=$snapshot_route"
echo "cjgui stage168 renderer-state write admission snapshot packet: renderer_state_write_admission_snapshot_packet_path=$RESULT_PACKET"
echo "cjgui stage168 renderer-state write admission snapshot packet: renderer_state_write=false"
