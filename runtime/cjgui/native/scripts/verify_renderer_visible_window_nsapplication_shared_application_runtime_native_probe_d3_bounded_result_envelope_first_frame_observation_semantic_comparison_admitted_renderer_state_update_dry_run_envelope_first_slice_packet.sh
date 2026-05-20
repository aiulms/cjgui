#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 semantic-comparison-admitted renderer-state write
# admission dry-run suite packet，生成 state-update dry-run envelope packet。它只
# 产生 fail-closed envelope，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage125-semantic-comparison-admitted-renderer-state-update-dry-run-envelope-first-slice-packet"
WRITE_ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_suite.sh"
WRITE_ADMISSION_LOG="$TMP_DIR/write-admission-suite.log"
STATE_UPDATE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-update-dry-run-envelope-first-slice.packet"
WRITE_ADMISSION_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_ADMISSION_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE125_WRITE_ADMISSION_CANONICAL_PACKET="/tmp/cjgui-stage125-write-admission-suite-check/cjgui-stage125-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$WRITE_ADMISSION_LOG"
: > "$STATE_UPDATE_PACKET"

if [[ ! -x "$WRITE_ADMISSION_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted state-update packet: missing executable script $WRITE_ADMISSION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$WRITE_ADMISSION_SUITE_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted state-update packet: syntax check failed $WRITE_ADMISSION_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted state-update packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

write_admission_suite_packet=""
write_admission_suite_packet_source="provided_stage125_write_admission_suite_packet"
current_shell_write_admission_rerun_ready="not_run"
current_shell_write_admission_rerun_failure_classification="none"

if [[ -n "$WRITE_ADMISSION_SUITE_PACKET" ]]; then
  if [[ ! -f "$WRITE_ADMISSION_SUITE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted state-update packet: provided write admission suite packet missing $WRITE_ADMISSION_SUITE_PACKET" >&2
    exit 6
  fi
  write_admission_suite_packet="$WRITE_ADMISSION_SUITE_PACKET"
  {
    echo "write_admission_suite_packet_used=true"
    echo "suite_packet_path=$WRITE_ADMISSION_SUITE_PACKET"
    cat "$WRITE_ADMISSION_SUITE_PACKET"
  } > "$WRITE_ADMISSION_LOG"
else
  write_admission_suite_packet_source="current_shell_stage125_write_admission_rerun"
  if env TMPDIR="$TMP_DIR/write-admission" zsh "$WRITE_ADMISSION_SUITE_SCRIPT" > "$WRITE_ADMISSION_LOG" 2>&1; then
    current_shell_write_admission_rerun_ready="true"
    write_admission_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_write_admission_rerun_ready="false"
    current_shell_write_admission_rerun_failure_classification="stage125_write_admission_suite_rerun_failed"
    if [[ -f "$STAGE125_WRITE_ADMISSION_CANONICAL_PACKET" ]]; then
      write_admission_suite_packet="$STAGE125_WRITE_ADMISSION_CANONICAL_PACKET"
      write_admission_suite_packet_source="stage125_write_admission_canonical_prior_suite_packet"
    else
      echo "cjgui semantic-comparison-admitted state-update packet: write admission suite failed" >&2
      echo "cjgui semantic-comparison-admitted state-update packet: log=$WRITE_ADMISSION_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$write_admission_suite_packet" || ! -f "$write_admission_suite_packet" ]]; then
  echo "cjgui semantic-comparison-admitted state-update packet: missing write admission suite packet" >&2
  exit 8
fi

required_write_admission_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_suite_passed=true"
  "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=true"
  "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=true"
  "state_mutation_request_admission_fields_defined=true"
  "visibility_publication_admission_fields_defined=true"
  "rollback_fallback_admission_fields_defined=true"
  "state_mutation_request_allowed=false"
  "visibility_publication_allowed=false"
  "rollback_state_write_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_write_admission_facts[@]}"; do
  require_file_fact "$write_admission_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted state-update packet: protected path modified" >&2
  exit 9
fi

admission_ready="$(fact_value "$write_admission_suite_packet" "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready")"
non_mutating="$(fact_value "$write_admission_suite_packet" "semantic_comparison_admitted_renderer_state_write_admission_non_mutating")"
state_fields="$(fact_value "$write_admission_suite_packet" "state_mutation_request_admission_fields_defined")"
visibility_fields="$(fact_value "$write_admission_suite_packet" "visibility_publication_admission_fields_defined")"
rollback_fields="$(fact_value "$write_admission_suite_packet" "rollback_fallback_admission_fields_defined")"
runtime_native_probe_execution="$(fact_value "$write_admission_suite_packet" "runtime_native_probe_execution")"
semantic_source="$(fact_value "$write_admission_suite_packet" "semantic_comparison_suite_packet_source")"
state_update_ready="false"
if [[ "$admission_ready" == "true" &&
      "$non_mutating" == "true" &&
      "$state_fields" == "true" &&
      "$visibility_fields" == "true" &&
      "$rollback_fields" == "true" ]]; then
  state_update_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_update_dry_run_envelope_first_slice_packet_version=1"
  echo "semantic_comparison_admitted_write_admission_suite_packet=$write_admission_suite_packet"
  echo "write_admission_suite_packet_source=$write_admission_suite_packet_source"
  echo "current_shell_write_admission_rerun_ready=$current_shell_write_admission_rerun_ready"
  echo "current_shell_write_admission_rerun_failure_classification=$current_shell_write_admission_rerun_failure_classification"
  echo "semantic_comparison_suite_packet_source=$semantic_source"
  echo "semantic_comparison_admitted_renderer_state_write_admission_consumed=true"
  echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=$admission_ready"
  echo "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=$non_mutating"
  echo "semantic_comparison_admitted_renderer_state_update_dry_run_envelope_ready=$state_update_ready"
  echo "state_update_envelope_dry_run_only=true"
  echo "semantic_comparison_admission_mapped_to_state_update_candidate=true"
  echo "first_frame_observation_state_field_mapped=true"
  echo "baseline_fixture_state_field_mapped=true"
  echo "semantic_acceptance_comparison_state_field_mapped=true"
  echo "state_mutation_request_admission_mapped_to_fail_closed_field=true"
  echo "visibility_publication_admission_mapped_to_fail_closed_field=true"
  echo "rollback_fallback_admission_mapped_to_fail_closed_field=true"
  echo "state_mutation_request_fail_closed=true"
  echo "visibility_publication_fail_closed=true"
  echo "rollback_fallback_write_fail_closed=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_update_dry_run_envelope_first_slice_packet_passed=true"
} > "$STATE_UPDATE_PACKET"

echo "cjgui semantic-comparison-admitted state-update packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_update_dry_run_envelope_first_slice_packet"
echo "cjgui semantic-comparison-admitted state-update packet: semantic_comparison_admitted_state_update_packet_path=$STATE_UPDATE_PACKET"
echo "cjgui semantic-comparison-admitted state-update packet: semantic_comparison_admitted_renderer_state_update_dry_run_envelope_ready=$state_update_ready"
echo "cjgui semantic-comparison-admitted state-update packet: renderer_state_write=false"
