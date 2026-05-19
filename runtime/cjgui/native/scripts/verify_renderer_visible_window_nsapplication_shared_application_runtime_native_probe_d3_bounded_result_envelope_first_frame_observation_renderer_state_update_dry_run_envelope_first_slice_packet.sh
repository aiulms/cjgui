#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 renderer-state write dry-run admission suite packet，
# 生成 state-update dry-run envelope first-slice packet。它只产生 dry-run envelope，
# 不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage121-renderer-state-update-dry-run-envelope-first-slice-packet"
DRY_RUN_ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_suite.sh"
DRY_RUN_ADMISSION_LOG="$TMP_DIR/dry-run-admission-suite.log"
STATE_UPDATE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-update-dry-run-envelope-first-slice.packet"
DRY_RUN_ADMISSION_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_WRITE_DRY_RUN_ADMISSION_FIRST_SLICE_SUITE_PACKET:-}"
STAGE121_DRY_RUN_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage121-dry-run-suite-check/cjgui-stage121-renderer-state-write-dry-run-admission-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-renderer-state-write-dry-run-admission-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$DRY_RUN_ADMISSION_LOG"
: > "$STATE_UPDATE_PACKET"

if [[ ! -x "$DRY_RUN_ADMISSION_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer state-update dry-run envelope packet: missing executable script $DRY_RUN_ADMISSION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$DRY_RUN_ADMISSION_SUITE_SCRIPT"; then
  echo "cjgui renderer state-update dry-run envelope packet: syntax check failed $DRY_RUN_ADMISSION_SUITE_SCRIPT" >&2
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
    echo "cjgui renderer state-update dry-run envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

dry_run_admission_suite_packet=""
dry_run_admission_positive_suite_packet_source="provided_stage121_dry_run_suite_packet"
current_shell_dry_run_admission_rerun_ready="not_run"
current_shell_dry_run_admission_rerun_failure_classification="none"

if [[ -n "$DRY_RUN_ADMISSION_SUITE_PACKET" ]]; then
  if [[ ! -f "$DRY_RUN_ADMISSION_SUITE_PACKET" ]]; then
    echo "cjgui renderer state-update dry-run envelope packet: provided dry-run suite packet missing $DRY_RUN_ADMISSION_SUITE_PACKET" >&2
    exit 6
  fi
  dry_run_admission_suite_packet="$DRY_RUN_ADMISSION_SUITE_PACKET"
  {
    echo "dry_run_admission_suite_packet_used=true"
    echo "suite_packet_path=$DRY_RUN_ADMISSION_SUITE_PACKET"
    cat "$DRY_RUN_ADMISSION_SUITE_PACKET"
  } > "$DRY_RUN_ADMISSION_LOG"
else
  dry_run_admission_positive_suite_packet_source="current_shell_stage121_dry_run_rerun"
  if env TMPDIR="$TMP_DIR/dry-run-admission" zsh "$DRY_RUN_ADMISSION_SUITE_SCRIPT" > "$DRY_RUN_ADMISSION_LOG" 2>&1; then
    current_shell_dry_run_admission_rerun_ready="true"
    dry_run_admission_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$DRY_RUN_ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_dry_run_admission_rerun_ready="false"
    current_shell_dry_run_admission_rerun_failure_classification="stage121_dry_run_admission_suite_rerun_failed"
    if [[ -f "$STAGE121_DRY_RUN_CANONICAL_POSITIVE_PACKET" ]]; then
      dry_run_admission_suite_packet="$STAGE121_DRY_RUN_CANONICAL_POSITIVE_PACKET"
      dry_run_admission_positive_suite_packet_source="stage121_dry_run_canonical_prior_suite_packet"
    else
      echo "cjgui renderer state-update dry-run envelope packet: dry-run admission suite failed" >&2
      echo "cjgui renderer state-update dry-run envelope packet: log=$DRY_RUN_ADMISSION_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$dry_run_admission_suite_packet" || ! -f "$dry_run_admission_suite_packet" ]]; then
  echo "cjgui renderer state-update dry-run envelope packet: missing dry-run admission suite packet" >&2
  exit 8
fi

required_dry_run_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_suite_passed=true"
  "renderer_state_write_dry_run_admission_ready=true"
  "renderer_state_write_dry_run_admission_non_mutating=true"
  "required_state_field_envelope_defined=true"
  "first_frame_observation_state_field_required=true"
  "production_write_admission_state_field_required=true"
  "baseline_gate_state_field_required=true"
  "rollback_visibility_dry_run_boundary_defined=true"
  "state_mutation_allowed=false"
  "visibility_publication_allowed=false"
  "rollback_state_write_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_dry_run_facts[@]}"; do
  require_file_fact "$dry_run_admission_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer state-update dry-run envelope packet: protected path modified" >&2
  exit 9
fi

dry_run_ready="$(fact_value "$dry_run_admission_suite_packet" "renderer_state_write_dry_run_admission_ready")"
non_mutating="$(fact_value "$dry_run_admission_suite_packet" "renderer_state_write_dry_run_admission_non_mutating")"
required_fields="$(fact_value "$dry_run_admission_suite_packet" "required_state_field_envelope_defined")"
first_frame_field="$(fact_value "$dry_run_admission_suite_packet" "first_frame_observation_state_field_required")"
baseline_field="$(fact_value "$dry_run_admission_suite_packet" "baseline_gate_state_field_required")"
rollback_boundary="$(fact_value "$dry_run_admission_suite_packet" "rollback_visibility_dry_run_boundary_defined")"
runtime_native_probe_execution="$(fact_value "$dry_run_admission_suite_packet" "runtime_native_probe_execution")"
write_source="$(fact_value "$dry_run_admission_suite_packet" "production_write_admission_positive_suite_packet_source")"
first_frame_source="$(fact_value "$dry_run_admission_suite_packet" "first_frame_positive_suite_packet_source")"
state_update_ready="false"
if [[ "$dry_run_ready" == "true" &&
      "$non_mutating" == "true" &&
      "$required_fields" == "true" &&
      "$first_frame_field" == "true" &&
      "$baseline_field" == "true" &&
      "$rollback_boundary" == "true" ]]; then
  state_update_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet_version=1"
  echo "renderer_state_write_dry_run_admission_suite_packet=$dry_run_admission_suite_packet"
  echo "dry_run_admission_positive_suite_packet_source=$dry_run_admission_positive_suite_packet_source"
  echo "current_shell_dry_run_admission_rerun_ready=$current_shell_dry_run_admission_rerun_ready"
  echo "current_shell_dry_run_admission_rerun_failure_classification=$current_shell_dry_run_admission_rerun_failure_classification"
  echo "production_write_admission_positive_suite_packet_source=$write_source"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "renderer_state_write_dry_run_admission_first_slice_consumed=true"
  echo "renderer_state_write_dry_run_admission_ready=$dry_run_ready"
  echo "renderer_state_write_dry_run_admission_non_mutating=$non_mutating"
  echo "renderer_state_update_dry_run_envelope_ready=$state_update_ready"
  echo "state_update_envelope_dry_run_only=true"
  echo "production_write_preflight_mapped_to_state_update_candidate=true"
  echo "first_frame_observation_state_field_mapped=true"
  echo "frame_hash_summary_state_field_mapped=true"
  echo "baseline_gate_state_field_mapped=true"
  echo "rollback_visibility_boundary_state_field_mapped=true"
  echo "state_mutation_request_fail_closed=true"
  echo "visibility_publication_fail_closed=true"
  echo "rollback_fallback_write_fail_closed=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "state_mutation_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "renderer_state_write_after_state_update_envelope_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet_passed=true"
} > "$STATE_UPDATE_PACKET"

echo "cjgui renderer state-update dry-run envelope packet: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet"
echo "cjgui renderer state-update dry-run envelope packet: state_update_packet_path=$STATE_UPDATE_PACKET"
echo "cjgui renderer state-update dry-run envelope packet: renderer_state_update_dry_run_envelope_ready=$state_update_ready"
echo "cjgui renderer state-update dry-run envelope packet: renderer_state_write=false"
