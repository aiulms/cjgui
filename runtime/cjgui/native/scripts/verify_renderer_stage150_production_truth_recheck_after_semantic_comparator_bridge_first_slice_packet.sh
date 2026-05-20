#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage150 production truth recheck packet。它消费
# stage149 comparator bridge，只分类 production truth gate 的缺口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE150_PACKET_TMPDIR:-/tmp/cjgui-stage150-production-truth-recheck-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_owner.sh"
STAGE149_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage149_semantic_comparator_bridge_after_stage148_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE149_LOG="$TMP_DIR/stage149.log"
RESULT_PACKET="$TMP_DIR/stage150-production-truth-recheck-after-semantic-comparator-bridge.packet"
STAGE149_SUITE_PACKET="${CJGUI_STAGE149_SEMANTIC_COMPARATOR_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage149"
: > "$OWNER_LOG"
: > "$STAGE149_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE149_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage150 production truth recheck packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage150 production truth recheck packet: syntax check failed $script" >&2
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
    echo "cjgui stage150 production truth recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage150 production truth recheck packet: owner probe failed" >&2
  echo "cjgui stage150 production truth recheck packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage150_production_truth_recheck_after_semantic_comparator_bridge_owner_present=true" \
  "stage149_semantic_comparator_bridge_packet_required=true" \
  "semantic_acceptance_runtime_before_production_truth_required=true" \
  "production_truth_recheck_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage149_input_mode="generated_stage149_suite_packet"
if [[ -n "$STAGE149_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE149_SUITE_PACKET" ]]; then
    echo "cjgui stage150 production truth recheck packet: provided stage149 suite packet missing $STAGE149_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage149_suite_packet_used=true"
    echo "stage149_suite_packet_path=$STAGE149_SUITE_PACKET"
  } > "$STAGE149_LOG"
  stage149_input_mode="provided_stage149_suite_packet"
else
  if ! env CJGUI_STAGE149_TMPDIR="$TMP_DIR/stage149" zsh "$STAGE149_SUITE_SCRIPT" > "$STAGE149_LOG" 2>&1; then
    echo "cjgui stage150 production truth recheck packet: stage149 suite failed" >&2
    echo "cjgui stage150 production truth recheck packet: log=$STAGE149_LOG" >&2
    exit 8
  fi
  STAGE149_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE149_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE149_SUITE_PACKET" || ! -f "$STAGE149_SUITE_PACKET" ]]; then
  echo "cjgui stage150 production truth recheck packet: missing stage149 suite packet" >&2
  exit 9
fi
for fact in \
  "stage149_semantic_comparator_bridge_after_stage148_first_slice_suite_passed=true" \
  "semantic_comparator_bridge_ready=true" \
  "semantic_comparator_bridge_source_ready=true" \
  "semantic_comparator_bridge_runtime_admitted=false" \
  "semantic_acceptance_runtime_admitted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE149_SUITE_PACKET" "$fact"
done

stage149_route="$(fact_value "$STAGE149_SUITE_PACKET" "semantic_comparator_bridge_route_classification")"
semantic_acceptance_runtime_admitted="$(fact_value "$STAGE149_SUITE_PACKET" "semantic_acceptance_runtime_admitted")"
backend_ready_truth="$(fact_value "$STAGE149_SUITE_PACKET" "backend_ready_truth")"
semantic_acceptance_runtime_admitted="${semantic_acceptance_runtime_admitted:-false}"
backend_ready_truth="${backend_ready_truth:-false}"

recheck_route="production_truth_recheck_blocked_missing_semantic_runtime_admission"
if [[ "$stage149_route" == "semantic_comparator_bridge_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  recheck_route="production_truth_recheck_blocked_host_metal_device_unavailable"
elif [[ "$semantic_acceptance_runtime_admitted" == "true" && "$backend_ready_truth" != "true" ]]; then
  recheck_route="production_truth_recheck_blocked_missing_backend_ready_truth"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage150 production truth recheck packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_packet_version=1"
  echo "stage149_input_mode=$stage149_input_mode"
  echo "stage149_suite_packet=$STAGE149_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage149_log=$STAGE149_LOG"
  echo "stage149_semantic_comparator_bridge_packet_consumed=true"
  echo "stage149_semantic_comparator_bridge_route_classification=$stage149_route"
  echo "semantic_acceptance_runtime_admitted=$semantic_acceptance_runtime_admitted"
  echo "backend_ready_truth=$backend_ready_truth"
  echo "production_truth_recheck_ready=true"
  echo "production_truth_recheck_allowed=false"
  echo "production_truth_recheck_route_classification=$recheck_route"
  echo "production_truth_recheck_missing_predicates=semantic_acceptance_runtime_admission,backend_ready_truth,result_envelope_promotion_token"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=metal_capable_rerun_or_renderer_state_write_token_gate_after_production_truth_recheck"
  echo "stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage150 production truth recheck packet: route_classification=$recheck_route"
echo "cjgui stage150 production truth recheck packet: production_truth_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage150 production truth recheck packet: renderer_state_write=false"
