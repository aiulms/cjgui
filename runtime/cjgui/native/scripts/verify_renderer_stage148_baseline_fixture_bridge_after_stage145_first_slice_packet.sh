#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage148 baseline fixture bridge packet。它消费
# stage145 suite 与旧 semantic comparison dry-run suite，输出 source bridge fact。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE148_PACKET_TMPDIR:-/tmp/cjgui-stage148-baseline-fixture-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice_owner.sh"
STAGE145_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage145_baseline_semantic_verification_after_write_decision_first_slice_suite.sh"
LEGACY_SEMANTIC_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE145_LOG="$TMP_DIR/stage145.log"
LEGACY_SEMANTIC_LOG="$TMP_DIR/legacy-semantic-comparison.log"
RESULT_PACKET="$TMP_DIR/stage148-baseline-fixture-bridge-after-stage145.packet"
STAGE145_SUITE_PACKET="${CJGUI_STAGE145_BASELINE_SEMANTIC_SUITE_PACKET:-}"
LEGACY_SEMANTIC_SUITE_PACKET="${CJGUI_LEGACY_SEMANTIC_COMPARISON_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage145" "$TMP_DIR/legacy-semantic"
: > "$OWNER_LOG"
: > "$STAGE145_LOG"
: > "$LEGACY_SEMANTIC_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE145_SUITE_SCRIPT" "$LEGACY_SEMANTIC_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage148 baseline fixture bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage148 baseline fixture bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage148 baseline fixture bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage148 baseline fixture bridge packet: owner probe failed" >&2
  echo "cjgui stage148 baseline fixture bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage148_baseline_fixture_bridge_after_stage145_owner_present=true" \
  "stage145_baseline_semantic_packet_required=true" \
  "legacy_semantic_comparison_fixture_packet_required=true" \
  "baseline_fixture_bridge_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage145_input_mode="generated_stage145_suite_packet"
if [[ -n "$STAGE145_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE145_SUITE_PACKET" ]]; then
    echo "cjgui stage148 baseline fixture bridge packet: provided stage145 suite packet missing $STAGE145_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage145_suite_packet_used=true"
    echo "stage145_suite_packet_path=$STAGE145_SUITE_PACKET"
  } > "$STAGE145_LOG"
  stage145_input_mode="provided_stage145_suite_packet"
else
  if ! env CJGUI_STAGE145_TMPDIR="$TMP_DIR/stage145" zsh "$STAGE145_SUITE_SCRIPT" > "$STAGE145_LOG" 2>&1; then
    echo "cjgui stage148 baseline fixture bridge packet: stage145 suite failed" >&2
    echo "cjgui stage148 baseline fixture bridge packet: log=$STAGE145_LOG" >&2
    exit 8
  fi
  STAGE145_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE145_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE145_SUITE_PACKET" || ! -f "$STAGE145_SUITE_PACKET" ]]; then
  echo "cjgui stage148 baseline fixture bridge packet: missing stage145 suite packet" >&2
  exit 9
fi
for fact in \
  "stage145_baseline_semantic_verification_after_write_decision_first_slice_suite_passed=true" \
  "baseline_semantic_verification_contract_ready=true" \
  "semantic_acceptance_admitted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE145_SUITE_PACKET" "$fact"
done
stage145_inner_packet="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_semantic_packet")"
if [[ -n "$stage145_inner_packet" && -f "$stage145_inner_packet" ]]; then
  require_file_fact "$stage145_inner_packet" "baseline_fixture_or_semantic_comparator_required=true"
  require_file_fact "$stage145_inner_packet" "baseline_comparison_executed=false"
fi

legacy_semantic_input_mode="generated_legacy_semantic_comparison_suite_packet"
if [[ -n "$LEGACY_SEMANTIC_SUITE_PACKET" ]]; then
  if [[ ! -f "$LEGACY_SEMANTIC_SUITE_PACKET" ]]; then
    echo "cjgui stage148 baseline fixture bridge packet: provided legacy semantic suite packet missing $LEGACY_SEMANTIC_SUITE_PACKET" >&2
    exit 10
  fi
  {
    echo "provided_legacy_semantic_suite_packet_used=true"
    echo "legacy_semantic_suite_packet_path=$LEGACY_SEMANTIC_SUITE_PACKET"
  } > "$LEGACY_SEMANTIC_LOG"
  legacy_semantic_input_mode="provided_legacy_semantic_comparison_suite_packet"
else
  if ! env TMPDIR="$TMP_DIR/legacy-semantic" zsh "$LEGACY_SEMANTIC_SUITE_SCRIPT" > "$LEGACY_SEMANTIC_LOG" 2>&1; then
    echo "cjgui stage148 baseline fixture bridge packet: legacy semantic suite failed" >&2
    echo "cjgui stage148 baseline fixture bridge packet: log=$LEGACY_SEMANTIC_LOG" >&2
    exit 11
  fi
  LEGACY_SEMANTIC_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$LEGACY_SEMANTIC_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$LEGACY_SEMANTIC_SUITE_PACKET" || ! -f "$LEGACY_SEMANTIC_SUITE_PACKET" ]]; then
  echo "cjgui stage148 baseline fixture bridge packet: missing legacy semantic suite packet" >&2
  exit 12
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_suite_passed=true" \
  "semantic_comparison_dry_run_ready=true" \
  "semantic_comparison_positive_fixture_matched=true" \
  "semantic_comparison_negative_fixture_rejected=true" \
  "semantic_acceptance_comparison_admitted=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$LEGACY_SEMANTIC_SUITE_PACKET" "$fact"
done

stage145_route="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_semantic_verification_route_classification")"
stage145_runtime_input_ready="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_semantic_verification_input_ready")"
legacy_positive="$(fact_value "$LEGACY_SEMANTIC_SUITE_PACKET" "semantic_comparison_positive_fixture_matched")"
legacy_negative="$(fact_value "$LEGACY_SEMANTIC_SUITE_PACKET" "semantic_comparison_negative_fixture_rejected")"
legacy_admitted="$(fact_value "$LEGACY_SEMANTIC_SUITE_PACKET" "semantic_acceptance_comparison_admitted")"
stage145_runtime_input_ready="${stage145_runtime_input_ready:-false}"
legacy_positive="${legacy_positive:-false}"
legacy_negative="${legacy_negative:-false}"
legacy_admitted="${legacy_admitted:-false}"

baseline_fixture_bridge_ready="false"
if [[ "$legacy_positive" == "true" && "$legacy_negative" == "true" && "$legacy_admitted" == "true" ]]; then
  baseline_fixture_bridge_ready="true"
fi

bridge_route="baseline_fixture_bridge_source_ready_runtime_blocked_missing_stage145_runtime_input"
if [[ "$stage145_route" == "host_metal_device_unavailable" ]]; then
  bridge_route="baseline_fixture_bridge_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$stage145_runtime_input_ready" == "true" ]]; then
  bridge_route="baseline_fixture_bridge_source_ready_runtime_pending_metal_capable_rerun"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage148 baseline fixture bridge packet: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage148_baseline_fixture_bridge_after_stage145_first_slice_packet_version=1"
  echo "stage145_input_mode=$stage145_input_mode"
  echo "stage145_suite_packet=$STAGE145_SUITE_PACKET"
  echo "legacy_semantic_input_mode=$legacy_semantic_input_mode"
  echo "legacy_semantic_comparison_suite_packet=$LEGACY_SEMANTIC_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage145_log=$STAGE145_LOG"
  echo "legacy_semantic_log=$LEGACY_SEMANTIC_LOG"
  echo "stage145_baseline_semantic_packet_consumed=true"
  echo "legacy_semantic_comparison_fixture_packet_consumed=true"
  echo "stage145_baseline_semantic_route_classification=$stage145_route"
  echo "stage145_baseline_semantic_runtime_input_ready=$stage145_runtime_input_ready"
  echo "baseline_fixture_source_contract_bound=true"
  echo "semantic_comparator_source_contract_bound=true"
  echo "legacy_semantic_comparison_positive_fixture_matched=$legacy_positive"
  echo "legacy_semantic_comparison_negative_fixture_rejected=$legacy_negative"
  echo "legacy_semantic_acceptance_comparison_admitted=$legacy_admitted"
  echo "legacy_comparator_source_contract_only=true"
  echo "baseline_fixture_bridge_ready=$baseline_fixture_bridge_ready"
  echo "baseline_fixture_bridge_runtime_admitted=false"
  echo "baseline_fixture_bridge_route_classification=$bridge_route"
  echo "baseline_fixture_bridge_runtime_missing_predicates=stage145_live_runtime_input,metal_capable_rerun,production_backend_truth"
  echo "baseline_comparison_executed=false"
  echo "baseline_compared=false"
  echo "semantic_acceptance_evaluated=false"
  echo "semantic_acceptance_admitted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=semantic_comparator_bridge_after_stage148"
  echo "stage148_baseline_fixture_bridge_after_stage145_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage148 baseline fixture bridge packet: route_classification=$bridge_route"
echo "cjgui stage148 baseline fixture bridge packet: baseline_fixture_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage148 baseline fixture bridge packet: renderer_state_write=false"
