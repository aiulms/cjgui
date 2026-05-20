#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage161 admission ledger packet，记录进入
# renderer-state write 前必须满足的正向 predicate 与缺失条件。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE161_PACKET_TMPDIR:-/tmp/cjgui-stage161-renderer-state-write-admission-ledger-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage161_renderer_state_write_admission_ledger_first_slice_owner.sh"
STAGE160_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage160_renderer_state_write_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE160_LOG="$TMP_DIR/stage160.log"
RESULT_PACKET="$TMP_DIR/stage161-renderer-state-write-admission-ledger-first-slice.packet"
STAGE160_SUITE_PACKET="${CJGUI_STAGE160_RENDERER_STATE_WRITE_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage160"
: > "$OWNER_LOG"
: > "$STAGE160_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE160_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage161 renderer-state write admission ledger packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage161 renderer-state write admission ledger packet: syntax check failed $script" >&2
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
    echo "cjgui stage161 renderer-state write admission ledger packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage161 renderer-state write admission ledger packet: owner probe failed" >&2
  echo "cjgui stage161 renderer-state write admission ledger packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage161_renderer_state_write_admission_ledger_owner_present=true" \
  "stage160_renderer_state_write_dry_run_required=true" \
  "renderer_state_write_admission_ledger_materialized=true" \
  "renderer_state_write_admission_positive_fixture_defined=true" \
  "renderer_state_write_precommit_visibility_boundary_input_prepared=true" \
  "renderer_state_write_admission_ledger_ready=true" \
  "renderer_state_write_admission_ledger_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage160_input_mode="generated_stage160_suite_packet"
if [[ -n "$STAGE160_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE160_SUITE_PACKET" ]]; then
    echo "cjgui stage161 renderer-state write admission ledger packet: provided stage160 suite packet missing $STAGE160_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage160_suite_packet_used=true" > "$STAGE160_LOG"
  stage160_input_mode="provided_stage160_suite_packet"
else
  if ! env CJGUI_STAGE160_TMPDIR="$TMP_DIR/stage160" zsh "$STAGE160_SUITE_SCRIPT" > "$STAGE160_LOG" 2>&1; then
    echo "cjgui stage161 renderer-state write admission ledger packet: stage160 suite failed" >&2
    echo "cjgui stage161 renderer-state write admission ledger packet: log=$STAGE160_LOG" >&2
    exit 8
  fi
  STAGE160_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE160_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE160_SUITE_PACKET" || ! -f "$STAGE160_SUITE_PACKET" ]]; then
  echo "cjgui stage161 renderer-state write admission ledger packet: missing stage160 suite packet" >&2
  exit 9
fi
for fact in \
  "stage160_renderer_state_write_dry_run_suite_passed=true" \
  "renderer_state_write_dry_run_ready=true" \
  "renderer_state_write_dry_run_source_ready=true" \
  "renderer_state_write_dry_run_runtime_admitted=false" \
  "renderer_state_write_dry_run_envelope_materialized=true" \
  "renderer_state_write_dry_run_positive_predicate_map_materialized=true" \
  "renderer_state_write_admission_ledger_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE160_SUITE_PACKET" "$fact"
done

stage160_route="$(fact_value "$STAGE160_SUITE_PACKET" "renderer_state_write_dry_run_route_classification")"
stage160_runtime_admitted="$(fact_value "$STAGE160_SUITE_PACKET" "renderer_state_write_dry_run_runtime_admitted")"
stage160_runtime_admitted="${stage160_runtime_admitted:-false}"
ledger_route="renderer_state_write_admission_ledger_blocked_stage160_runtime_admission"
if [[ "$stage160_route" == "renderer_state_write_dry_run_blocked_host_metal_device_unavailable" ]]; then
  ledger_route="renderer_state_write_admission_ledger_blocked_host_metal_device_unavailable"
elif [[ "$stage160_runtime_admitted" == "true" ]]; then
  ledger_route="renderer_state_write_admission_ledger_ready_for_precommit_visibility_boundary"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage161 renderer-state write admission ledger packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage161_renderer_state_write_admission_ledger_packet_version=1"
  echo "stage160_input_mode=$stage160_input_mode"
  echo "stage160_suite_packet=$STAGE160_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage160_log=$STAGE160_LOG"
  echo "stage160_renderer_state_write_dry_run_consumed=true"
  echo "stage160_renderer_state_write_dry_run_route_classification=$stage160_route"
  echo "stage160_renderer_state_write_dry_run_runtime_admitted=$stage160_runtime_admitted"
  echo "renderer_state_write_admission_ledger_route_classification=$ledger_route"
  echo "renderer_state_write_admission_ledger_ready=true"
  echo "renderer_state_write_admission_ledger_source_ready=true"
  echo "renderer_state_write_admission_ledger_runtime_admitted=false"
  echo "renderer_state_write_admission_ledger_materialized=true"
  echo "production_truth_predicate_recorded=true"
  echo "semantic_comparison_predicate_recorded=true"
  echo "write_token_gate_predicate_recorded=true"
  echo "mutation_dry_run_predicate_recorded=true"
  echo "guarded_executor_predicate_recorded=true"
  echo "visibility_result_predicate_recorded=true"
  echo "rollback_boundary_predicate_recorded=true"
  echo "renderer_state_write_admission_missing_predicates=production_render_truth,backend_ready_truth,semantic_acceptance_runtime_admission,result_envelope_promotion_token,stage160_runtime_admission"
  echo "renderer_state_write_admission_positive_fixture_defined=true"
  echo "renderer_state_write_admission_predicates_satisfied=false"
  echo "renderer_state_write_precommit_visibility_boundary_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage162_renderer_state_write_precommit_visibility_boundary_first_slice_after_admission_ledger"
  echo "stage161_renderer_state_write_admission_ledger_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage161 renderer-state write admission ledger packet: route_classification=$ledger_route"
echo "cjgui stage161 renderer-state write admission ledger packet: renderer_state_write_admission_ledger_packet_path=$RESULT_PACKET"
echo "cjgui stage161 renderer-state write admission ledger packet: renderer_state_write=false"
