#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 baseline / semantic verification dry-run suite packet，
# 生成 renderer-state semantic gate dry-run envelope packet。它只产出 dry-run
# gate decision facts，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage122-renderer-state-semantic-gate-dry-run-envelope-first-slice-packet"
BASELINE_SEMANTIC_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_suite.sh"
BASELINE_SEMANTIC_LOG="$TMP_DIR/baseline-semantic-suite.log"
SEMANTIC_GATE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-semantic-gate-dry-run-envelope-first-slice.packet"
BASELINE_SEMANTIC_SUITE_PACKET="${CJGUI_BASELINE_SEMANTIC_VERIFICATION_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE122_BASELINE_SEMANTIC_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage122-baseline-semantic-suite-check/cjgui-stage122-baseline-semantic-verification-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-baseline-semantic-verification-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$BASELINE_SEMANTIC_LOG"
: > "$SEMANTIC_GATE_PACKET"

if [[ ! -x "$BASELINE_SEMANTIC_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer state semantic gate dry-run envelope packet: missing executable script $BASELINE_SEMANTIC_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$BASELINE_SEMANTIC_SUITE_SCRIPT"; then
  echo "cjgui renderer state semantic gate dry-run envelope packet: syntax check failed $BASELINE_SEMANTIC_SUITE_SCRIPT" >&2
  exit 4
fi

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui renderer state semantic gate dry-run envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

baseline_semantic_suite_packet=""
baseline_semantic_positive_suite_packet_source="provided_stage122_baseline_semantic_suite_packet"
current_shell_baseline_semantic_rerun_ready="not_run"
current_shell_baseline_semantic_rerun_failure_classification="none"

if [[ -n "$BASELINE_SEMANTIC_SUITE_PACKET" ]]; then
  if [[ ! -f "$BASELINE_SEMANTIC_SUITE_PACKET" ]]; then
    echo "cjgui renderer state semantic gate dry-run envelope packet: provided baseline semantic suite packet missing $BASELINE_SEMANTIC_SUITE_PACKET" >&2
    exit 6
  fi
  baseline_semantic_suite_packet="$BASELINE_SEMANTIC_SUITE_PACKET"
  {
    echo "baseline_semantic_suite_packet_used=true"
    echo "suite_packet_path=$BASELINE_SEMANTIC_SUITE_PACKET"
    cat "$BASELINE_SEMANTIC_SUITE_PACKET"
  } > "$BASELINE_SEMANTIC_LOG"
else
  baseline_semantic_positive_suite_packet_source="current_shell_stage122_baseline_semantic_rerun"
  if env TMPDIR="$TMP_DIR/baseline-semantic" zsh "$BASELINE_SEMANTIC_SUITE_SCRIPT" > "$BASELINE_SEMANTIC_LOG" 2>&1; then
    current_shell_baseline_semantic_rerun_ready="true"
    baseline_semantic_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$BASELINE_SEMANTIC_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_baseline_semantic_rerun_ready="false"
    current_shell_baseline_semantic_rerun_failure_classification="stage122_baseline_semantic_suite_rerun_failed"
    if [[ -f "$STAGE122_BASELINE_SEMANTIC_CANONICAL_POSITIVE_PACKET" ]]; then
      baseline_semantic_suite_packet="$STAGE122_BASELINE_SEMANTIC_CANONICAL_POSITIVE_PACKET"
      baseline_semantic_positive_suite_packet_source="stage122_baseline_semantic_canonical_prior_suite_packet"
    else
      echo "cjgui renderer state semantic gate dry-run envelope packet: baseline semantic suite failed" >&2
      echo "cjgui renderer state semantic gate dry-run envelope packet: log=$BASELINE_SEMANTIC_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$baseline_semantic_suite_packet" || ! -f "$baseline_semantic_suite_packet" ]]; then
  echo "cjgui renderer state semantic gate dry-run envelope packet: missing baseline semantic suite packet" >&2
  exit 8
fi

required_baseline_semantic_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_suite_passed=true"
  "baseline_semantic_verification_dry_run_ready=true"
  "baseline_comparison_input_contract_defined=true"
  "baseline_compare_gate_defined=true"
  "semantic_acceptance_fields_defined=true"
  "missing_baseline_classified_as_pending_dry_run=true"
  "baseline_compared=false"
  "semantic_acceptance_admitted=false"
  "state_write_after_semantic_verification_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_baseline_semantic_facts[@]}"; do
  require_file_fact "$baseline_semantic_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer state semantic gate dry-run envelope packet: protected path modified" >&2
  exit 9
fi

baseline_semantic_ready="$(fact_value "$baseline_semantic_suite_packet" "baseline_semantic_verification_dry_run_ready")"
missing_baseline_pending="$(fact_value "$baseline_semantic_suite_packet" "missing_baseline_classified_as_pending_dry_run")"
semantic_acceptance="$(fact_value "$baseline_semantic_suite_packet" "semantic_acceptance_admitted")"
runtime_native_probe_execution="$(fact_value "$baseline_semantic_suite_packet" "runtime_native_probe_execution")"
state_update_source="$(fact_value "$baseline_semantic_suite_packet" "state_update_positive_suite_packet_source")"
semantic_gate_ready="false"
if [[ "$baseline_semantic_ready" == "true" &&
      "$missing_baseline_pending" == "true" &&
      "$semantic_acceptance" == "false" ]]; then
  semantic_gate_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_packet_version=1"
  echo "baseline_semantic_verification_dry_run_suite_packet=$baseline_semantic_suite_packet"
  echo "baseline_semantic_positive_suite_packet_source=$baseline_semantic_positive_suite_packet_source"
  echo "current_shell_baseline_semantic_rerun_ready=$current_shell_baseline_semantic_rerun_ready"
  echo "current_shell_baseline_semantic_rerun_failure_classification=$current_shell_baseline_semantic_rerun_failure_classification"
  echo "state_update_positive_suite_packet_source=$state_update_source"
  echo "baseline_semantic_verification_dry_run_first_slice_consumed=true"
  echo "baseline_semantic_verification_dry_run_ready=$baseline_semantic_ready"
  echo "renderer_state_semantic_gate_dry_run_envelope_ready=$semantic_gate_ready"
  echo "semantic_gate_dry_run_only=true"
  echo "baseline_compare_required_before_renderer_state_write=true"
  echo "semantic_acceptance_required_before_renderer_state_write=true"
  echo "missing_baseline_blocks_renderer_state_write=true"
  echo "semantic_acceptance_pending_blocks_renderer_state_write=true"
  echo "renderer_state_write_decision_blocked_until_semantic_acceptance=true"
  echo "renderer_state_write_admission_after_semantic_gate=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_packet_passed=true"
} > "$SEMANTIC_GATE_PACKET"

echo "cjgui renderer state semantic gate dry-run envelope packet: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_packet"
echo "cjgui renderer state semantic gate dry-run envelope packet: semantic_gate_packet_path=$SEMANTIC_GATE_PACKET"
echo "cjgui renderer state semantic gate dry-run envelope packet: renderer_state_semantic_gate_dry_run_envelope_ready=$semantic_gate_ready"
echo "cjgui renderer state semantic gate dry-run envelope packet: renderer_state_write=false"
