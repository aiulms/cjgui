#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage145 baseline / semantic verification packet。它消费
# stage144 write decision suite packet，分类 baseline / semantic verification 的
# 最小输入状态，不比较 baseline，不升级 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE145_PACKET_TMPDIR:-/tmp/cjgui-stage145-baseline-semantic-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage145_baseline_semantic_verification_after_write_decision_first_slice_owner.sh"
STAGE144_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_after_truth_admission_contract_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE144_LOG="$TMP_DIR/stage144.log"
RESULT_PACKET="$TMP_DIR/stage145-baseline-semantic-verification-after-write-decision.packet"
STAGE144_SUITE_PACKET="${CJGUI_STAGE144_WRITE_DECISION_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage144"
: > "$OWNER_LOG"
: > "$STAGE144_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE144_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage145 baseline semantic packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage145 baseline semantic packet: syntax check failed $script" >&2
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
    echo "cjgui stage145 baseline semantic packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage145 baseline semantic packet: owner probe failed" >&2
  echo "cjgui stage145 baseline semantic packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage145_baseline_semantic_verification_after_write_decision_owner_present=true" \
  "stage144_write_decision_packet_required=true" \
  "truth_admission_preflight_before_baseline_semantic_required=true" \
  "positive_first_frame_before_baseline_semantic_required=true" \
  "baseline_comparison_non_mutating=true" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage144_input_mode="generated_stage144_suite_packet"
if [[ -n "$STAGE144_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE144_SUITE_PACKET" ]]; then
    echo "cjgui stage145 baseline semantic packet: provided stage144 suite packet missing $STAGE144_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage144_suite_packet_used=true"
    echo "stage144_suite_packet_path=$STAGE144_SUITE_PACKET"
  } > "$STAGE144_LOG"
  stage144_input_mode="provided_stage144_suite_packet"
else
  if ! env CJGUI_STAGE144_TMPDIR="$TMP_DIR/stage144" zsh "$STAGE144_SUITE_SCRIPT" > "$STAGE144_LOG" 2>&1; then
    echo "cjgui stage145 baseline semantic packet: stage144 suite failed" >&2
    echo "cjgui stage145 baseline semantic packet: log=$STAGE144_LOG" >&2
    exit 8
  fi
  STAGE144_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE144_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE144_SUITE_PACKET" || ! -f "$STAGE144_SUITE_PACKET" ]]; then
  echo "cjgui stage145 baseline semantic packet: missing stage144 suite packet" >&2
  exit 9
fi
for fact in \
  "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_suite_passed=true" \
  "renderer_state_write_decision_ready=true" \
  "renderer_state_write_allowed=false" \
  "renderer_state_write_denied=true" \
  "renderer_state_write_decision_non_mutating=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE144_SUITE_PACKET" "$fact"
done

stage144_route="$(fact_value "$STAGE144_SUITE_PACKET" "renderer_state_write_decision_route_classification")"
truth_preflight="$(fact_value "$STAGE144_SUITE_PACKET" "truth_admission_preflight_ready")"
positive_first_frame="$(fact_value "$STAGE144_SUITE_PACKET" "positive_first_frame_input_ready")"
production_render_truth="$(fact_value "$STAGE144_SUITE_PACKET" "production_render_truth")"
backend_ready_truth="$(fact_value "$STAGE144_SUITE_PACKET" "backend_ready_truth")"
truth_preflight="${truth_preflight:-false}"
positive_first_frame="${positive_first_frame:-false}"
production_render_truth="${production_render_truth:-false}"
backend_ready_truth="${backend_ready_truth:-false}"

baseline_semantic_input_ready="false"
baseline_semantic_route="baseline_semantic_verification_blocked_pending_truth_admission"
baseline_semantic_missing_predicates="positive_first_frame_observation,frame_hash_nonzero,baseline_fixture_or_semantic_comparator,backend_ready_truth"
if [[ "$stage144_route" == "renderer_state_write_decision_denied_host_metal_device_unavailable" ]]; then
  baseline_semantic_route="host_metal_device_unavailable"
elif [[ "$stage144_route" == "renderer_state_write_decision_denied_host_window_capture_unavailable" ]]; then
  baseline_semantic_route="host_window_capture_unavailable"
elif [[ "$truth_preflight" == "true" && "$positive_first_frame" == "true" ]]; then
  baseline_semantic_input_ready="true"
  baseline_semantic_route="baseline_semantic_verification_pending_fixture_or_comparator"
  baseline_semantic_missing_predicates="baseline_fixture_or_semantic_comparator,backend_ready_truth,production_write_admission"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage145 baseline semantic packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage145_baseline_semantic_verification_after_write_decision_first_slice_packet_version=1"
  echo "stage144_input_mode=$stage144_input_mode"
  echo "stage144_suite_packet=$STAGE144_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage144_log=$STAGE144_LOG"
  echo "stage144_write_decision_packet_consumed=true"
  echo "stage144_write_decision_route_classification=$stage144_route"
  echo "truth_admission_preflight_ready=$truth_preflight"
  echo "positive_first_frame_input_ready=$positive_first_frame"
  echo "baseline_semantic_verification_contract_ready=true"
  echo "baseline_semantic_verification_input_ready=$baseline_semantic_input_ready"
  echo "baseline_semantic_verification_route_classification=$baseline_semantic_route"
  echo "baseline_semantic_missing_predicates=$baseline_semantic_missing_predicates"
  echo "baseline_fixture_or_semantic_comparator_required=true"
  echo "baseline_comparison_executed=false"
  echo "baseline_compared=false"
  echo "semantic_acceptance_evaluated=false"
  echo "semantic_acceptance_admitted=false"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=$production_render_truth"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "production_write_admission=false"
  echo "renderer_state_write_after_baseline_semantic_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_truth_promotion_after_baseline_semantic_contract"
  echo "stage145_baseline_semantic_verification_after_write_decision_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage145 baseline semantic packet: route_classification=$baseline_semantic_route"
echo "cjgui stage145 baseline semantic packet: baseline_semantic_packet_path=$RESULT_PACKET"
echo "cjgui stage145 baseline semantic packet: renderer_state_write=false"
