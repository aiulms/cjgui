#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage156 renderer-state write first-slice readiness
# contract packet。它把 stage155 rollback boundary 与 legacy terminal denial
# 汇总为非变更 precondition ledger / positive dry-run candidate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE156_PACKET_TMPDIR:-/tmp/cjgui-stage156-renderer-state-write-readiness-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage156_renderer_state_write_first_slice_readiness_contract_owner.sh"
STAGE155_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage155_rollback_visibility_boundary_bridge_first_slice_suite.sh"
LEGACY_TERMINAL_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE155_LOG="$TMP_DIR/stage155.log"
LEGACY_TERMINAL_LOG="$TMP_DIR/legacy-terminal.log"
RESULT_PACKET="$TMP_DIR/stage156-renderer-state-write-first-slice-readiness-contract.packet"
STAGE155_SUITE_PACKET="${CJGUI_STAGE155_ROLLBACK_VISIBILITY_BOUNDARY_SUITE_PACKET:-}"
LEGACY_TERMINAL_PACKET="${CJGUI_STAGE128_TERMINAL_WRITE_DENIAL_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage155" "$TMP_DIR/legacy-terminal"
: > "$OWNER_LOG"
: > "$STAGE155_LOG"
: > "$LEGACY_TERMINAL_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE155_SUITE_SCRIPT" "$LEGACY_TERMINAL_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage156 renderer-state write readiness packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage156 renderer-state write readiness packet: syntax check failed $script" >&2
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
    echo "cjgui stage156 renderer-state write readiness packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage156 renderer-state write readiness packet: owner probe failed" >&2
  echo "cjgui stage156 renderer-state write readiness packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage156_renderer_state_write_first_slice_readiness_contract_owner_present=true" \
  "stage155_rollback_visibility_boundary_packet_required=true" \
  "legacy_terminal_write_denial_packet_required=true" \
  "renderer_state_write_first_slice_precondition_ledger_materialized=true" \
  "renderer_state_write_positive_dry_run_candidate_defined=true" \
  "renderer_state_write_first_slice_readiness_contract_ready=true" \
  "renderer_state_write_first_slice_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage155_input_mode="generated_stage155_suite_packet"
if [[ -n "$STAGE155_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE155_SUITE_PACKET" ]]; then
    echo "cjgui stage156 renderer-state write readiness packet: provided stage155 suite packet missing $STAGE155_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage155_suite_packet_used=true" > "$STAGE155_LOG"
  stage155_input_mode="provided_stage155_suite_packet"
else
  if ! env CJGUI_STAGE155_TMPDIR="$TMP_DIR/stage155" zsh "$STAGE155_SUITE_SCRIPT" > "$STAGE155_LOG" 2>&1; then
    echo "cjgui stage156 renderer-state write readiness packet: stage155 suite failed" >&2
    echo "cjgui stage156 renderer-state write readiness packet: log=$STAGE155_LOG" >&2
    exit 8
  fi
  STAGE155_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE155_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE155_SUITE_PACKET" || ! -f "$STAGE155_SUITE_PACKET" ]]; then
  echo "cjgui stage156 renderer-state write readiness packet: missing stage155 suite packet" >&2
  exit 9
fi
for fact in \
  "stage155_rollback_visibility_boundary_bridge_first_slice_suite_passed=true" \
  "rollback_visibility_boundary_bridge_ready=true" \
  "rollback_visibility_boundary_runtime_admitted=false" \
  "rollback_visibility_positive_predicate_map_materialized=true" \
  "rollback_visibility_boundary_positive_fixture_defined=true" \
  "renderer_state_write_first_slice_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE155_SUITE_PACKET" "$fact"
done

stage155_bridge_packet="$(fact_value "$STAGE155_SUITE_PACKET" "rollback_visibility_boundary_bridge_packet")"
legacy_rollback_packet=""
if [[ -n "$stage155_bridge_packet" && -f "$stage155_bridge_packet" ]]; then
  legacy_rollback_packet="$(fact_value "$stage155_bridge_packet" "legacy_rollback_fallback_denial_packet")"
fi

legacy_terminal_input_mode="generated_legacy_terminal_packet"
if [[ -n "$LEGACY_TERMINAL_PACKET" ]]; then
  if [[ ! -f "$LEGACY_TERMINAL_PACKET" ]]; then
    echo "cjgui stage156 renderer-state write readiness packet: provided legacy terminal packet missing $LEGACY_TERMINAL_PACKET" >&2
    exit 10
  fi
  echo "provided_legacy_terminal_packet_used=true" > "$LEGACY_TERMINAL_LOG"
  legacy_terminal_input_mode="provided_legacy_terminal_packet"
else
  if [[ -z "$legacy_rollback_packet" || ! -f "$legacy_rollback_packet" ]]; then
    echo "cjgui stage156 renderer-state write readiness packet: missing stage155 legacy rollback packet" >&2
    exit 11
  fi
  if ! env CJGUI_STAGE128_TMPDIR="$TMP_DIR/legacy-terminal" \
    CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_ROLLBACK_FALLBACK_DENIAL_ENVELOPE_FIRST_SLICE_PACKET="$legacy_rollback_packet" \
    zsh "$LEGACY_TERMINAL_PACKET_SCRIPT" > "$LEGACY_TERMINAL_LOG" 2>&1; then
    echo "cjgui stage156 renderer-state write readiness packet: legacy terminal packet failed" >&2
    echo "cjgui stage156 renderer-state write readiness packet: log=$LEGACY_TERMINAL_LOG" >&2
    exit 12
  fi
  LEGACY_TERMINAL_PACKET="$(grep -Eo 'terminal_write_denial_envelope_packet_path=[^[:space:]]+' "$LEGACY_TERMINAL_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$LEGACY_TERMINAL_PACKET" || ! -f "$LEGACY_TERMINAL_PACKET" ]]; then
  echo "cjgui stage156 renderer-state write readiness packet: missing legacy terminal packet" >&2
  exit 13
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true" \
  "terminal_write_denial_envelope_materialized=true" \
  "terminal_renderer_state_write_denied=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$LEGACY_TERMINAL_PACKET" "$fact"
done

stage155_route="$(fact_value "$STAGE155_SUITE_PACKET" "rollback_visibility_boundary_route_classification")"
stage155_runtime_admitted="$(fact_value "$STAGE155_SUITE_PACKET" "rollback_visibility_boundary_runtime_admitted")"
stage155_runtime_admitted="${stage155_runtime_admitted:-false}"
write_route="renderer_state_write_first_slice_readiness_contract_blocked_rollback_visibility_boundary"
if [[ "$stage155_route" == "rollback_visibility_boundary_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  write_route="renderer_state_write_first_slice_readiness_contract_blocked_host_metal_device_unavailable"
elif [[ "$stage155_runtime_admitted" == "true" ]]; then
  write_route="renderer_state_write_first_slice_readiness_contract_blocked_terminal_write_denial"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage156 renderer-state write readiness packet: protected production bridge/state path modified" >&2
  exit 14
fi

{
  echo "stage156_renderer_state_write_first_slice_readiness_contract_packet_version=1"
  echo "stage155_input_mode=$stage155_input_mode"
  echo "legacy_terminal_input_mode=$legacy_terminal_input_mode"
  echo "stage155_suite_packet=$STAGE155_SUITE_PACKET"
  echo "stage155_rollback_visibility_boundary_bridge_packet=$stage155_bridge_packet"
  echo "legacy_terminal_write_denial_packet=$LEGACY_TERMINAL_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage155_log=$STAGE155_LOG"
  echo "legacy_terminal_log=$LEGACY_TERMINAL_LOG"
  echo "stage155_rollback_visibility_boundary_packet_consumed=true"
  echo "legacy_terminal_write_denial_packet_consumed=true"
  echo "stage155_rollback_visibility_boundary_route_classification=$stage155_route"
  echo "rollback_visibility_boundary_runtime_admitted=$stage155_runtime_admitted"
  echo "renderer_state_write_first_slice_readiness_contract_ready=true"
  echo "renderer_state_write_first_slice_source_ready=true"
  echo "renderer_state_write_first_slice_runtime_admitted=false"
  echo "renderer_state_write_first_slice_route_classification=$write_route"
  echo "renderer_state_write_first_slice_precondition_ledger_materialized=true"
  echo "production_truth_predicate_bound=true"
  echo "semantic_comparison_predicate_bound=true"
  echo "write_token_gate_predicate_bound=true"
  echo "mutation_request_runtime_predicate_bound=true"
  echo "guarded_executor_runtime_predicate_bound=true"
  echo "visibility_publication_runtime_predicate_bound=true"
  echo "rollback_visibility_boundary_predicate_bound=true"
  echo "renderer_state_write_positive_dry_run_candidate_defined=true"
  echo "renderer_state_write_first_slice_predicates_satisfied=false"
  echo "renderer_state_write_first_slice_execution_blocked=true"
  echo "terminal_write_denial_envelope_consumed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=metal_capable_rerun_stage156_or_state_write_internal_owner_first_slice_after_positive_truth"
  echo "stage156_renderer_state_write_first_slice_readiness_contract_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage156 renderer-state write readiness packet: route_classification=$write_route"
echo "cjgui stage156 renderer-state write readiness packet: renderer_state_write_first_slice_readiness_packet_path=$RESULT_PACKET"
echo "cjgui stage156 renderer-state write readiness packet: renderer_state_write=false"
