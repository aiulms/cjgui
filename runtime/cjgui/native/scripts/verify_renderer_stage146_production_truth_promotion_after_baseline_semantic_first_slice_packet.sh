#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage146 production truth promotion packet。它消费
# stage145 baseline / semantic suite packet，只输出 promotion readiness / denial
# envelope，不发布 production render truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE146_PACKET_TMPDIR:-/tmp/cjgui-stage146-production-truth-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage146_production_truth_promotion_after_baseline_semantic_first_slice_owner.sh"
STAGE145_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage145_baseline_semantic_verification_after_write_decision_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE145_LOG="$TMP_DIR/stage145.log"
RESULT_PACKET="$TMP_DIR/stage146-production-truth-promotion-after-baseline-semantic.packet"
STAGE145_SUITE_PACKET="${CJGUI_STAGE145_BASELINE_SEMANTIC_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage145"
: > "$OWNER_LOG"
: > "$STAGE145_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE145_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage146 production truth packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage146 production truth packet: syntax check failed $script" >&2
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
    echo "cjgui stage146 production truth packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage146 production truth packet: owner probe failed" >&2
  echo "cjgui stage146 production truth packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage146_production_truth_promotion_after_baseline_semantic_owner_present=true" \
  "stage145_baseline_semantic_packet_required=true" \
  "baseline_compared_before_production_truth_required=true" \
  "semantic_acceptance_before_production_truth_required=true" \
  "production_truth_promotion_non_mutating=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage145_input_mode="generated_stage145_suite_packet"
if [[ -n "$STAGE145_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE145_SUITE_PACKET" ]]; then
    echo "cjgui stage146 production truth packet: provided stage145 suite packet missing $STAGE145_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage145_suite_packet_used=true"
    echo "stage145_suite_packet_path=$STAGE145_SUITE_PACKET"
  } > "$STAGE145_LOG"
  stage145_input_mode="provided_stage145_suite_packet"
else
  if ! env CJGUI_STAGE145_TMPDIR="$TMP_DIR/stage145" zsh "$STAGE145_SUITE_SCRIPT" > "$STAGE145_LOG" 2>&1; then
    echo "cjgui stage146 production truth packet: stage145 suite failed" >&2
    echo "cjgui stage146 production truth packet: log=$STAGE145_LOG" >&2
    exit 8
  fi
  STAGE145_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE145_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE145_SUITE_PACKET" || ! -f "$STAGE145_SUITE_PACKET" ]]; then
  echo "cjgui stage146 production truth packet: missing stage145 suite packet" >&2
  exit 9
fi
for fact in \
  "stage145_baseline_semantic_verification_after_write_decision_first_slice_suite_passed=true" \
  "baseline_semantic_verification_contract_ready=true" \
  "baseline_compared=false" \
  "semantic_acceptance_admitted=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE145_SUITE_PACKET" "$fact"
done

stage145_route="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_semantic_verification_route_classification")"
baseline_input_ready="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_semantic_verification_input_ready")"
baseline_compared="$(fact_value "$STAGE145_SUITE_PACKET" "baseline_compared")"
semantic_acceptance="$(fact_value "$STAGE145_SUITE_PACKET" "semantic_acceptance_admitted")"
backend_ready_truth="$(fact_value "$STAGE145_SUITE_PACKET" "backend_ready_truth")"
baseline_input_ready="${baseline_input_ready:-false}"
baseline_compared="${baseline_compared:-false}"
semantic_acceptance="${semantic_acceptance:-false}"
backend_ready_truth="${backend_ready_truth:-false}"

promotion_route="production_truth_promotion_blocked_pending_baseline_semantic"
promotion_allowed="false"
promotion_missing_predicates="baseline_compared,semantic_acceptance,backend_ready_truth"
if [[ "$stage145_route" == "host_metal_device_unavailable" ]]; then
  promotion_route="host_metal_device_unavailable"
elif [[ "$stage145_route" == "host_window_capture_unavailable" ]]; then
  promotion_route="host_window_capture_unavailable"
elif [[ "$baseline_input_ready" == "true" &&
        "$baseline_compared" == "true" &&
        "$semantic_acceptance" == "true" &&
        "$backend_ready_truth" == "true" ]]; then
  promotion_route="production_truth_promotion_pending_explicit_admission"
  promotion_missing_predicates="production_truth_admission_token"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage146 production truth packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage146_production_truth_promotion_after_baseline_semantic_first_slice_packet_version=1"
  echo "stage145_input_mode=$stage145_input_mode"
  echo "stage145_suite_packet=$STAGE145_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage145_log=$STAGE145_LOG"
  echo "stage145_baseline_semantic_packet_consumed=true"
  echo "stage145_baseline_semantic_route_classification=$stage145_route"
  echo "baseline_semantic_verification_input_ready=$baseline_input_ready"
  echo "baseline_compared=$baseline_compared"
  echo "semantic_acceptance_admitted=$semantic_acceptance"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "production_truth_promotion_contract_ready=true"
  echo "production_truth_promotion_route_classification=$promotion_route"
  echo "production_truth_promotion_missing_predicates=$promotion_missing_predicates"
  echo "production_truth_promotion_allowed=$promotion_allowed"
  echo "production_truth_promotion_non_mutating=true"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "production_write_admission=false"
  echo "renderer_state_write_after_production_truth_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=renderer_state_write_admission_after_production_truth_contract"
  echo "stage146_production_truth_promotion_after_baseline_semantic_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage146 production truth packet: route_classification=$promotion_route"
echo "cjgui stage146 production truth packet: production_truth_packet_path=$RESULT_PACKET"
echo "cjgui stage146 production truth packet: renderer_state_write=false"
