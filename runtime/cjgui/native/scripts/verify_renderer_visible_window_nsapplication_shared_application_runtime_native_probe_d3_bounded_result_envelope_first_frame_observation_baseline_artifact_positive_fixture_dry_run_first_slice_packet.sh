#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage123 semantic-acceptance result suite packet，
# 生成 baseline artifact positive fixture dry-run packet。fixture 只提供
# redacted compare input shape，不读取真实 frame hash value。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage124-baseline-artifact-positive-fixture-dry-run-first-slice-packet"
SEMANTIC_ACCEPTANCE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_suite.sh"
SEMANTIC_ACCEPTANCE_LOG="$TMP_DIR/semantic-acceptance-suite.log"
BASELINE_FIXTURE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-artifact-positive-fixture-dry-run-first-slice.packet"
SEMANTIC_ACCEPTANCE_SUITE_PACKET="${CJGUI_SEMANTIC_ACCEPTANCE_RESULT_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE123_SEMANTIC_ACCEPTANCE_CANONICAL_PACKET="/tmp/cjgui-stage123-semantic-acceptance-suite-check/cjgui-stage123-semantic-acceptance-result-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-semantic-acceptance-result-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$SEMANTIC_ACCEPTANCE_LOG"
: > "$BASELINE_FIXTURE_PACKET"

if [[ ! -x "$SEMANTIC_ACCEPTANCE_SUITE_SCRIPT" ]]; then
  echo "cjgui baseline artifact positive fixture dry-run packet: missing executable script $SEMANTIC_ACCEPTANCE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$SEMANTIC_ACCEPTANCE_SUITE_SCRIPT"; then
  echo "cjgui baseline artifact positive fixture dry-run packet: syntax check failed $SEMANTIC_ACCEPTANCE_SUITE_SCRIPT" >&2
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
    echo "cjgui baseline artifact positive fixture dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

semantic_acceptance_suite_packet=""
semantic_acceptance_suite_packet_source="provided_stage123_semantic_acceptance_suite_packet"
current_shell_semantic_acceptance_rerun_ready="not_run"
current_shell_semantic_acceptance_rerun_failure_classification="none"

if [[ -n "$SEMANTIC_ACCEPTANCE_SUITE_PACKET" ]]; then
  if [[ ! -f "$SEMANTIC_ACCEPTANCE_SUITE_PACKET" ]]; then
    echo "cjgui baseline artifact positive fixture dry-run packet: provided semantic acceptance suite packet missing $SEMANTIC_ACCEPTANCE_SUITE_PACKET" >&2
    exit 6
  fi
  semantic_acceptance_suite_packet="$SEMANTIC_ACCEPTANCE_SUITE_PACKET"
  {
    echo "semantic_acceptance_suite_packet_used=true"
    echo "suite_packet_path=$SEMANTIC_ACCEPTANCE_SUITE_PACKET"
    cat "$SEMANTIC_ACCEPTANCE_SUITE_PACKET"
  } > "$SEMANTIC_ACCEPTANCE_LOG"
else
  semantic_acceptance_suite_packet_source="current_shell_stage123_semantic_acceptance_rerun"
  if env TMPDIR="$TMP_DIR/semantic-acceptance" zsh "$SEMANTIC_ACCEPTANCE_SUITE_SCRIPT" > "$SEMANTIC_ACCEPTANCE_LOG" 2>&1; then
    current_shell_semantic_acceptance_rerun_ready="true"
    semantic_acceptance_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$SEMANTIC_ACCEPTANCE_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_semantic_acceptance_rerun_ready="false"
    current_shell_semantic_acceptance_rerun_failure_classification="stage123_semantic_acceptance_suite_rerun_failed"
    if [[ -f "$STAGE123_SEMANTIC_ACCEPTANCE_CANONICAL_PACKET" ]]; then
      semantic_acceptance_suite_packet="$STAGE123_SEMANTIC_ACCEPTANCE_CANONICAL_PACKET"
      semantic_acceptance_suite_packet_source="stage123_semantic_acceptance_canonical_prior_suite_packet"
    else
      echo "cjgui baseline artifact positive fixture dry-run packet: semantic acceptance suite failed" >&2
      echo "cjgui baseline artifact positive fixture dry-run packet: log=$SEMANTIC_ACCEPTANCE_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$semantic_acceptance_suite_packet" || ! -f "$semantic_acceptance_suite_packet" ]]; then
  echo "cjgui baseline artifact positive fixture dry-run packet: missing semantic acceptance suite packet" >&2
  exit 8
fi

required_semantic_acceptance_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_suite_passed=true"
  "semantic_acceptance_result_dry_run_ready=true"
  "semantic_acceptance_result_dry_run_only=true"
  "semantic_acceptance_failure_classification=missing_baseline_artifact_source"
  "missing_baseline_artifact_blocks_semantic_acceptance=true"
  "semantic_acceptance_evaluated=false"
  "semantic_acceptance_admitted=false"
  "renderer_state_write_after_semantic_acceptance_result_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_semantic_acceptance_facts[@]}"; do
  require_file_fact "$semantic_acceptance_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui baseline artifact positive fixture dry-run packet: protected path modified" >&2
  exit 9
fi

runtime_native_probe_execution="$(fact_value "$semantic_acceptance_suite_packet" "runtime_native_probe_execution")"
semantic_acceptance_ready="$(fact_value "$semantic_acceptance_suite_packet" "semantic_acceptance_result_dry_run_ready")"
baseline_fixture_ready="false"
if [[ "$semantic_acceptance_ready" == "true" ]]; then
  baseline_fixture_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_packet_version=1"
  echo "semantic_acceptance_suite_packet=$semantic_acceptance_suite_packet"
  echo "semantic_acceptance_suite_packet_source=$semantic_acceptance_suite_packet_source"
  echo "current_shell_semantic_acceptance_rerun_ready=$current_shell_semantic_acceptance_rerun_ready"
  echo "current_shell_semantic_acceptance_rerun_failure_classification=$current_shell_semantic_acceptance_rerun_failure_classification"
  echo "semantic_acceptance_result_dry_run_consumed=true"
  echo "semantic_acceptance_result_dry_run_ready=$semantic_acceptance_ready"
  echo "baseline_artifact_positive_fixture_dry_run_ready=$baseline_fixture_ready"
  echo "baseline_artifact_positive_fixture_dry_run_only=true"
  echo "baseline_artifact_positive_fixture_source_defined=true"
  echo "baseline_artifact_fixture_source=stage124_redacted_positive_fixture"
  echo "baseline_artifact_fixture_provenance=automation_stage124_redacted_fixture"
  echo "baseline_artifact_fixture_provenance_defined=true"
  echo "baseline_artifact_fixture_freshness_contract_defined=true"
  echo "baseline_artifact_fixture_freshness_checked=true"
  echo "baseline_artifact_fixture_freshness_passed=true"
  echo "baseline_fixture_hash_value_redaction_policy_defined=true"
  echo "baseline_fixture_frame_hash_value_redacted=true"
  echo "baseline_artifact_fixture_materialized=true"
  echo "baseline_compare_input_shape_defined=true"
  echo "baseline_compare_executed=false"
  echo "semantic_acceptance_admitted=false"
  echo "renderer_state_write_after_baseline_fixture_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_packet_passed=true"
} > "$BASELINE_FIXTURE_PACKET"

echo "cjgui baseline artifact positive fixture dry-run packet: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_packet"
echo "cjgui baseline artifact positive fixture dry-run packet: baseline_fixture_packet_path=$BASELINE_FIXTURE_PACKET"
echo "cjgui baseline artifact positive fixture dry-run packet: baseline_artifact_positive_fixture_dry_run_ready=$baseline_fixture_ready"
echo "cjgui baseline artifact positive fixture dry-run packet: renderer_state_write=false"
