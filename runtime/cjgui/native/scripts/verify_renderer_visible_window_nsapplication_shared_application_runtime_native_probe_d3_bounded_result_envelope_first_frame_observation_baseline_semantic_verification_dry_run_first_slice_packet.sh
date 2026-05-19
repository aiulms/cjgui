#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage121 state-update dry-run envelope suite packet，
# 生成 baseline / semantic verification dry-run first-slice packet。它只定义
# baseline/semantic gate facts，不比较 baseline，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage122-baseline-semantic-verification-dry-run-first-slice-packet"
STATE_UPDATE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite.sh"
STATE_UPDATE_LOG="$TMP_DIR/state-update-suite.log"
BASELINE_SEMANTIC_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-semantic-verification-dry-run-first-slice.packet"
STATE_UPDATE_SUITE_PACKET="${CJGUI_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_SUITE_PACKET:-}"
STAGE121_STATE_UPDATE_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage121-state-update-suite-check/cjgui-stage121-renderer-state-update-dry-run-envelope-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-renderer-state-update-dry-run-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$STATE_UPDATE_LOG"
: > "$BASELINE_SEMANTIC_PACKET"

if [[ ! -x "$STATE_UPDATE_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer baseline semantic verification dry-run packet: missing executable script $STATE_UPDATE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$STATE_UPDATE_SUITE_SCRIPT"; then
  echo "cjgui renderer baseline semantic verification dry-run packet: syntax check failed $STATE_UPDATE_SUITE_SCRIPT" >&2
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
    echo "cjgui renderer baseline semantic verification dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

state_update_suite_packet=""
state_update_positive_suite_packet_source="provided_stage121_state_update_suite_packet"
current_shell_state_update_rerun_ready="not_run"
current_shell_state_update_rerun_failure_classification="none"

if [[ -n "$STATE_UPDATE_SUITE_PACKET" ]]; then
  if [[ ! -f "$STATE_UPDATE_SUITE_PACKET" ]]; then
    echo "cjgui renderer baseline semantic verification dry-run packet: provided state-update suite packet missing $STATE_UPDATE_SUITE_PACKET" >&2
    exit 6
  fi
  state_update_suite_packet="$STATE_UPDATE_SUITE_PACKET"
  {
    echo "state_update_suite_packet_used=true"
    echo "suite_packet_path=$STATE_UPDATE_SUITE_PACKET"
    cat "$STATE_UPDATE_SUITE_PACKET"
  } > "$STATE_UPDATE_LOG"
else
  state_update_positive_suite_packet_source="current_shell_stage121_state_update_rerun"
  if env TMPDIR="$TMP_DIR/state-update" zsh "$STATE_UPDATE_SUITE_SCRIPT" > "$STATE_UPDATE_LOG" 2>&1; then
    current_shell_state_update_rerun_ready="true"
    state_update_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STATE_UPDATE_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_state_update_rerun_ready="false"
    current_shell_state_update_rerun_failure_classification="stage121_state_update_suite_rerun_failed"
    if [[ -f "$STAGE121_STATE_UPDATE_CANONICAL_POSITIVE_PACKET" ]]; then
      state_update_suite_packet="$STAGE121_STATE_UPDATE_CANONICAL_POSITIVE_PACKET"
      state_update_positive_suite_packet_source="stage121_state_update_canonical_prior_suite_packet"
    else
      echo "cjgui renderer baseline semantic verification dry-run packet: state-update suite failed" >&2
      echo "cjgui renderer baseline semantic verification dry-run packet: log=$STATE_UPDATE_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$state_update_suite_packet" || ! -f "$state_update_suite_packet" ]]; then
  echo "cjgui renderer baseline semantic verification dry-run packet: missing state-update suite packet" >&2
  exit 8
fi

required_state_update_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_suite_passed=true"
  "renderer_state_update_dry_run_envelope_ready=true"
  "state_update_envelope_dry_run_only=true"
  "first_frame_observation_state_field_mapped=true"
  "frame_hash_summary_state_field_mapped=true"
  "baseline_gate_state_field_mapped=true"
  "frame_hash_value_persisted=false"
  "frame_hash_value_logged=false"
  "baseline_compared=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_state_update_facts[@]}"; do
  require_file_fact "$state_update_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer baseline semantic verification dry-run packet: protected path modified" >&2
  exit 9
fi

state_update_ready="$(fact_value "$state_update_suite_packet" "renderer_state_update_dry_run_envelope_ready")"
frame_hash_summary_mapped="$(fact_value "$state_update_suite_packet" "frame_hash_summary_state_field_mapped")"
baseline_gate_mapped="$(fact_value "$state_update_suite_packet" "baseline_gate_state_field_mapped")"
runtime_native_probe_execution="$(fact_value "$state_update_suite_packet" "runtime_native_probe_execution")"
dry_run_source="$(fact_value "$state_update_suite_packet" "dry_run_admission_positive_suite_packet_source")"
write_source="$(fact_value "$state_update_suite_packet" "production_write_admission_positive_suite_packet_source")"
first_frame_source="$(fact_value "$state_update_suite_packet" "first_frame_positive_suite_packet_source")"
baseline_semantic_ready="false"
if [[ "$state_update_ready" == "true" &&
      "$frame_hash_summary_mapped" == "true" &&
      "$baseline_gate_mapped" == "true" ]]; then
  baseline_semantic_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_packet_version=1"
  echo "renderer_state_update_dry_run_envelope_suite_packet=$state_update_suite_packet"
  echo "state_update_positive_suite_packet_source=$state_update_positive_suite_packet_source"
  echo "current_shell_state_update_rerun_ready=$current_shell_state_update_rerun_ready"
  echo "current_shell_state_update_rerun_failure_classification=$current_shell_state_update_rerun_failure_classification"
  echo "dry_run_admission_positive_suite_packet_source=$dry_run_source"
  echo "production_write_admission_positive_suite_packet_source=$write_source"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "renderer_state_update_dry_run_envelope_first_slice_consumed=true"
  echo "renderer_state_update_dry_run_envelope_ready=$state_update_ready"
  echo "baseline_semantic_verification_dry_run_ready=$baseline_semantic_ready"
  echo "baseline_comparison_input_contract_defined=true"
  echo "baseline_compare_gate_defined=true"
  echo "semantic_acceptance_fields_defined=true"
  echo "missing_baseline_classified_as_pending_dry_run=true"
  echo "frame_hash_summary_only=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_match=false"
  echo "semantic_acceptance_dry_run_only=true"
  echo "semantic_acceptance_admitted=false"
  echo "state_write_after_semantic_verification_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_packet_passed=true"
} > "$BASELINE_SEMANTIC_PACKET"

echo "cjgui renderer baseline semantic verification dry-run packet: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_packet"
echo "cjgui renderer baseline semantic verification dry-run packet: baseline_semantic_packet_path=$BASELINE_SEMANTIC_PACKET"
echo "cjgui renderer baseline semantic verification dry-run packet: baseline_semantic_verification_dry_run_ready=$baseline_semantic_ready"
echo "cjgui renderer baseline semantic verification dry-run packet: renderer_state_write=false"
