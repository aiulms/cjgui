#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage147 renderer-state write admission packet。它消费
# stage146 production-truth suite packet，分类 write admission denial，不写状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE147_PACKET_TMPDIR:-/tmp/cjgui-stage147-write-admission-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage147_renderer_state_write_admission_after_production_truth_first_slice_owner.sh"
STAGE146_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage146_production_truth_promotion_after_baseline_semantic_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE146_LOG="$TMP_DIR/stage146.log"
RESULT_PACKET="$TMP_DIR/stage147-renderer-state-write-admission-after-production-truth.packet"
STAGE146_SUITE_PACKET="${CJGUI_STAGE146_PRODUCTION_TRUTH_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage146"
: > "$OWNER_LOG"
: > "$STAGE146_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE146_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage147 write admission packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage147 write admission packet: syntax check failed $script" >&2
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
    echo "cjgui stage147 write admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage147 write admission packet: owner probe failed" >&2
  echo "cjgui stage147 write admission packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage147_renderer_state_write_admission_after_production_truth_owner_present=true" \
  "stage146_production_truth_packet_required=true" \
  "production_render_truth_before_write_admission_required=true" \
  "backend_ready_truth_before_write_admission_required=true" \
  "renderer_state_write_admission_non_mutating=true" \
  "state_mutation_request_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage146_input_mode="generated_stage146_suite_packet"
if [[ -n "$STAGE146_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE146_SUITE_PACKET" ]]; then
    echo "cjgui stage147 write admission packet: provided stage146 suite packet missing $STAGE146_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage146_suite_packet_used=true"
    echo "stage146_suite_packet_path=$STAGE146_SUITE_PACKET"
  } > "$STAGE146_LOG"
  stage146_input_mode="provided_stage146_suite_packet"
else
  if ! env CJGUI_STAGE146_TMPDIR="$TMP_DIR/stage146" zsh "$STAGE146_SUITE_SCRIPT" > "$STAGE146_LOG" 2>&1; then
    echo "cjgui stage147 write admission packet: stage146 suite failed" >&2
    echo "cjgui stage147 write admission packet: log=$STAGE146_LOG" >&2
    exit 8
  fi
  STAGE146_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE146_LOG" | tail -1 | cut -d= -f2-)"
fi

if [[ -z "$STAGE146_SUITE_PACKET" || ! -f "$STAGE146_SUITE_PACKET" ]]; then
  echo "cjgui stage147 write admission packet: missing stage146 suite packet" >&2
  exit 9
fi
for fact in \
  "stage146_production_truth_promotion_after_baseline_semantic_first_slice_suite_passed=true" \
  "production_truth_promotion_contract_ready=true" \
  "production_truth_promotion_allowed=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE146_SUITE_PACKET" "$fact"
done

stage146_route="$(fact_value "$STAGE146_SUITE_PACKET" "production_truth_promotion_route_classification")"
production_truth="$(fact_value "$STAGE146_SUITE_PACKET" "production_render_truth")"
backend_ready_truth="$(fact_value "$STAGE146_SUITE_PACKET" "backend_ready_truth")"
result_promoted="$(fact_value "$STAGE146_SUITE_PACKET" "result_envelope_promoted_to_production_truth")"
production_truth="${production_truth:-false}"
backend_ready_truth="${backend_ready_truth:-false}"
result_promoted="${result_promoted:-false}"

write_admission_route="renderer_state_write_admission_denied_missing_production_truth"
write_admission_missing_predicates="production_render_truth,backend_ready_truth,production_write_admission_token,state_mutation_request_envelope"
if [[ "$stage146_route" == "host_metal_device_unavailable" ]]; then
  write_admission_route="renderer_state_write_admission_denied_host_metal_device_unavailable"
elif [[ "$stage146_route" == "host_window_capture_unavailable" ]]; then
  write_admission_route="renderer_state_write_admission_denied_host_window_capture_unavailable"
elif [[ "$production_truth" == "true" &&
        "$backend_ready_truth" == "true" &&
        "$result_promoted" == "true" ]]; then
  write_admission_route="renderer_state_write_admission_pending_explicit_write_token"
  write_admission_missing_predicates="production_write_admission_token,state_mutation_request_envelope"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage147 write admission packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage147_renderer_state_write_admission_after_production_truth_first_slice_packet_version=1"
  echo "stage146_input_mode=$stage146_input_mode"
  echo "stage146_suite_packet=$STAGE146_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage146_log=$STAGE146_LOG"
  echo "stage146_production_truth_packet_consumed=true"
  echo "stage146_production_truth_route_classification=$stage146_route"
  echo "production_render_truth=$production_truth"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "result_envelope_promoted_to_production_truth=$result_promoted"
  echo "production_write_admission=false"
  echo "renderer_state_write_admission_contract_ready=true"
  echo "renderer_state_write_admission_route_classification=$write_admission_route"
  echo "renderer_state_write_admission_missing_predicates=$write_admission_missing_predicates"
  echo "renderer_state_write_admission_allowed=false"
  echo "renderer_state_write_admission_non_mutating=true"
  echo "state_mutation_request_envelope_ready=false"
  echo "state_mutation_request_blocked=true"
  echo "state_mutation_executed=false"
  echo "visibility_publication_blocked=true"
  echo "visibility_published=false"
  echo "rollback_required=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=metal_capable_rerun_or_state_mutation_request_envelope_after_write_admission"
  echo "stage147_renderer_state_write_admission_after_production_truth_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage147 write admission packet: route_classification=$write_admission_route"
echo "cjgui stage147 write admission packet: write_admission_packet_path=$RESULT_PACKET"
echo "cjgui stage147 write admission packet: renderer_state_write=false"
