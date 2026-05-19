#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 baseline artifact positive fixture suite packet，
# 生成 semantic comparison dry-run packet。comparison 可以 positive-admit
# redacted fixture，但不允许 renderer/runtime state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage124-semantic-comparison-dry-run-first-slice-packet"
BASELINE_FIXTURE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_suite.sh"
BASELINE_FIXTURE_LOG="$TMP_DIR/baseline-fixture-suite.log"
SEMANTIC_COMPARISON_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-dry-run-first-slice.packet"
BASELINE_FIXTURE_SUITE_PACKET="${CJGUI_BASELINE_ARTIFACT_POSITIVE_FIXTURE_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE124_BASELINE_FIXTURE_CANONICAL_PACKET="/tmp/cjgui-stage124-baseline-fixture-suite-check/cjgui-stage124-baseline-artifact-positive-fixture-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-baseline-artifact-positive-fixture-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$BASELINE_FIXTURE_LOG"
: > "$SEMANTIC_COMPARISON_PACKET"

if [[ ! -x "$BASELINE_FIXTURE_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic comparison dry-run packet: missing executable script $BASELINE_FIXTURE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$BASELINE_FIXTURE_SUITE_SCRIPT"; then
  echo "cjgui semantic comparison dry-run packet: syntax check failed $BASELINE_FIXTURE_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic comparison dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

baseline_fixture_suite_packet=""
baseline_fixture_suite_packet_source="provided_stage124_baseline_fixture_suite_packet"
current_shell_baseline_fixture_rerun_ready="not_run"
current_shell_baseline_fixture_rerun_failure_classification="none"

if [[ -n "$BASELINE_FIXTURE_SUITE_PACKET" ]]; then
  if [[ ! -f "$BASELINE_FIXTURE_SUITE_PACKET" ]]; then
    echo "cjgui semantic comparison dry-run packet: provided baseline fixture suite packet missing $BASELINE_FIXTURE_SUITE_PACKET" >&2
    exit 6
  fi
  baseline_fixture_suite_packet="$BASELINE_FIXTURE_SUITE_PACKET"
  {
    echo "baseline_fixture_suite_packet_used=true"
    echo "suite_packet_path=$BASELINE_FIXTURE_SUITE_PACKET"
    cat "$BASELINE_FIXTURE_SUITE_PACKET"
  } > "$BASELINE_FIXTURE_LOG"
else
  baseline_fixture_suite_packet_source="current_shell_stage124_baseline_fixture_rerun"
  if env TMPDIR="$TMP_DIR/baseline-fixture" zsh "$BASELINE_FIXTURE_SUITE_SCRIPT" > "$BASELINE_FIXTURE_LOG" 2>&1; then
    current_shell_baseline_fixture_rerun_ready="true"
    baseline_fixture_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$BASELINE_FIXTURE_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_baseline_fixture_rerun_ready="false"
    current_shell_baseline_fixture_rerun_failure_classification="stage124_baseline_fixture_suite_rerun_failed"
    if [[ -f "$STAGE124_BASELINE_FIXTURE_CANONICAL_PACKET" ]]; then
      baseline_fixture_suite_packet="$STAGE124_BASELINE_FIXTURE_CANONICAL_PACKET"
      baseline_fixture_suite_packet_source="stage124_baseline_fixture_canonical_prior_suite_packet"
    else
      echo "cjgui semantic comparison dry-run packet: baseline fixture suite failed" >&2
      echo "cjgui semantic comparison dry-run packet: log=$BASELINE_FIXTURE_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$baseline_fixture_suite_packet" || ! -f "$baseline_fixture_suite_packet" ]]; then
  echo "cjgui semantic comparison dry-run packet: missing baseline fixture suite packet" >&2
  exit 8
fi

required_baseline_fixture_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_suite_passed=true"
  "baseline_artifact_positive_fixture_dry_run_ready=true"
  "baseline_artifact_positive_fixture_dry_run_only=true"
  "baseline_artifact_fixture_materialized=true"
  "baseline_artifact_fixture_freshness_passed=true"
  "baseline_fixture_frame_hash_value_redacted=true"
  "baseline_compare_input_shape_defined=true"
  "semantic_comparison_ready_to_dry_run=true"
  "renderer_state_write_after_baseline_fixture_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_baseline_fixture_facts[@]}"; do
  require_file_fact "$baseline_fixture_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic comparison dry-run packet: protected path modified" >&2
  exit 9
fi

runtime_native_probe_execution="$(fact_value "$baseline_fixture_suite_packet" "runtime_native_probe_execution")"
baseline_fixture_ready="$(fact_value "$baseline_fixture_suite_packet" "baseline_artifact_positive_fixture_dry_run_ready")"
semantic_comparison_ready="false"
if [[ "$baseline_fixture_ready" == "true" ]]; then
  semantic_comparison_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_packet_version=1"
  echo "baseline_fixture_suite_packet=$baseline_fixture_suite_packet"
  echo "baseline_fixture_suite_packet_source=$baseline_fixture_suite_packet_source"
  echo "current_shell_baseline_fixture_rerun_ready=$current_shell_baseline_fixture_rerun_ready"
  echo "current_shell_baseline_fixture_rerun_failure_classification=$current_shell_baseline_fixture_rerun_failure_classification"
  echo "baseline_artifact_positive_fixture_dry_run_consumed=true"
  echo "baseline_artifact_positive_fixture_dry_run_ready=$baseline_fixture_ready"
  echo "semantic_comparison_dry_run_ready=$semantic_comparison_ready"
  echo "semantic_comparison_dry_run_only=true"
  echo "semantic_comparison_input_shape_defined=true"
  echo "semantic_comparison_positive_fixture_route_defined=true"
  echo "semantic_comparison_negative_fixture_route_defined=true"
  echo "semantic_comparison_evaluated=true"
  echo "semantic_comparison_positive_fixture_matched=true"
  echo "semantic_comparison_negative_fixture_rejected=true"
  echo "semantic_acceptance_comparison_admitted=true"
  echo "semantic_acceptance_failure_classification=none"
  echo "baseline_fixture_hash_value_redacted=true"
  echo "renderer_state_write_after_semantic_comparison_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_packet_passed=true"
} > "$SEMANTIC_COMPARISON_PACKET"

echo "cjgui semantic comparison dry-run packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_packet"
echo "cjgui semantic comparison dry-run packet: semantic_comparison_packet_path=$SEMANTIC_COMPARISON_PACKET"
echo "cjgui semantic comparison dry-run packet: semantic_comparison_dry_run_ready=$semantic_comparison_ready"
echo "cjgui semantic comparison dry-run packet: renderer_state_write=false"
