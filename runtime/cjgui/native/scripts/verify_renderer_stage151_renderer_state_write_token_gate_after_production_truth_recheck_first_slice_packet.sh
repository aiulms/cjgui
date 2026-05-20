#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage151 renderer-state write token gate packet。
# 它消费 stage150 production truth recheck，只分类 write token 缺口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE151_PACKET_TMPDIR:-/tmp/cjgui-stage151-write-token-gate-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice_owner.sh"
STAGE150_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE150_LOG="$TMP_DIR/stage150.log"
RESULT_PACKET="$TMP_DIR/stage151-renderer-state-write-token-gate-after-production-truth-recheck.packet"
STAGE150_SUITE_PACKET="${CJGUI_STAGE150_PRODUCTION_TRUTH_RECHECK_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage150"
: > "$OWNER_LOG"
: > "$STAGE150_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE150_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage151 write token gate packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage151 write token gate packet: syntax check failed $script" >&2
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
    echo "cjgui stage151 write token gate packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage151 write token gate packet: owner probe failed" >&2
  echo "cjgui stage151 write token gate packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage151_renderer_state_write_token_gate_after_production_truth_recheck_owner_present=true" \
  "production_truth_recheck_allowed_before_write_token_required=true" \
  "backend_ready_truth_before_write_token_required=true" \
  "state_mutation_request_envelope_before_write_token_required=true" \
  "renderer_state_write_token_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage150_input_mode="generated_stage150_suite_packet"
if [[ -n "$STAGE150_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE150_SUITE_PACKET" ]]; then
    echo "cjgui stage151 write token gate packet: provided stage150 suite packet missing $STAGE150_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage150_suite_packet_used=true"
    echo "stage150_suite_packet_path=$STAGE150_SUITE_PACKET"
  } > "$STAGE150_LOG"
  stage150_input_mode="provided_stage150_suite_packet"
else
  if ! env CJGUI_STAGE150_TMPDIR="$TMP_DIR/stage150" zsh "$STAGE150_SUITE_SCRIPT" > "$STAGE150_LOG" 2>&1; then
    echo "cjgui stage151 write token gate packet: stage150 suite failed" >&2
    echo "cjgui stage151 write token gate packet: log=$STAGE150_LOG" >&2
    exit 8
  fi
  STAGE150_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE150_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE150_SUITE_PACKET" || ! -f "$STAGE150_SUITE_PACKET" ]]; then
  echo "cjgui stage151 write token gate packet: missing stage150 suite packet" >&2
  exit 9
fi
for fact in \
  "stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_suite_passed=true" \
  "production_truth_recheck_ready=true" \
  "production_truth_recheck_allowed=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE150_SUITE_PACKET" "$fact"
done

stage150_route="$(fact_value "$STAGE150_SUITE_PACKET" "production_truth_recheck_route_classification")"
production_truth_recheck_allowed="$(fact_value "$STAGE150_SUITE_PACKET" "production_truth_recheck_allowed")"
backend_ready_truth="$(fact_value "$STAGE150_SUITE_PACKET" "backend_ready_truth")"
production_truth_recheck_allowed="${production_truth_recheck_allowed:-false}"
backend_ready_truth="${backend_ready_truth:-false}"

write_token_route="renderer_state_write_token_gate_denied_missing_production_truth_recheck"
if [[ "$stage150_route" == "production_truth_recheck_blocked_host_metal_device_unavailable" ]]; then
  write_token_route="renderer_state_write_token_gate_denied_host_metal_device_unavailable"
elif [[ "$production_truth_recheck_allowed" == "true" && "$backend_ready_truth" != "true" ]]; then
  write_token_route="renderer_state_write_token_gate_denied_missing_backend_ready_truth"
elif [[ "$production_truth_recheck_allowed" == "true" && "$backend_ready_truth" == "true" ]]; then
  write_token_route="renderer_state_write_token_gate_denied_missing_mutation_request_envelope"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage151 write token gate packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice_packet_version=1"
  echo "stage150_input_mode=$stage150_input_mode"
  echo "stage150_suite_packet=$STAGE150_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage150_log=$STAGE150_LOG"
  echo "stage150_production_truth_recheck_packet_consumed=true"
  echo "stage150_production_truth_recheck_route_classification=$stage150_route"
  echo "production_truth_recheck_allowed=$production_truth_recheck_allowed"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "renderer_state_write_token_gate_ready=true"
  echo "renderer_state_write_token_allowed=false"
  echo "renderer_state_write_token_gate_route_classification=$write_token_route"
  echo "renderer_state_write_token_missing_predicates=production_truth_recheck_allowed,production_render_truth,backend_ready_truth,state_mutation_request_envelope"
  echo "state_mutation_request_blocked=true"
  echo "visibility_publication_blocked=true"
  echo "production_render_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=mutation_request_bridge_after_write_token_gate"
  echo "stage151_renderer_state_write_token_gate_after_production_truth_recheck_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage151 write token gate packet: route_classification=$write_token_route"
echo "cjgui stage151 write token gate packet: write_token_gate_packet_path=$RESULT_PACKET"
echo "cjgui stage151 write token gate packet: renderer_state_write=false"
