#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage149 semantic comparator bridge packet。它消费
# stage148 packet，并把 comparator source-ready 与 runtime blocked 原因拆清楚。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE149_PACKET_TMPDIR:-/tmp/cjgui-stage149-semantic-comparator-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage149_semantic_comparator_bridge_after_stage148_first_slice_owner.sh"
STAGE148_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE148_LOG="$TMP_DIR/stage148.log"
RESULT_PACKET="$TMP_DIR/stage149-semantic-comparator-bridge-after-stage148.packet"
STAGE148_SUITE_PACKET="${CJGUI_STAGE148_BASELINE_FIXTURE_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage148"
: > "$OWNER_LOG"
: > "$STAGE148_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE148_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage149 semantic comparator bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage149 semantic comparator bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage149 semantic comparator bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage149 semantic comparator bridge packet: owner probe failed" >&2
  echo "cjgui stage149 semantic comparator bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage149_semantic_comparator_bridge_after_stage148_owner_present=true" \
  "stage148_baseline_fixture_bridge_packet_required=true" \
  "semantic_comparator_bridge_source_ready_required=true" \
  "semantic_comparator_bridge_runtime_non_admitting=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage148_input_mode="generated_stage148_suite_packet"
if [[ -n "$STAGE148_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE148_SUITE_PACKET" ]]; then
    echo "cjgui stage149 semantic comparator bridge packet: provided stage148 suite packet missing $STAGE148_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage148_suite_packet_used=true"
    echo "stage148_suite_packet_path=$STAGE148_SUITE_PACKET"
  } > "$STAGE148_LOG"
  stage148_input_mode="provided_stage148_suite_packet"
else
  if ! env CJGUI_STAGE148_TMPDIR="$TMP_DIR/stage148" zsh "$STAGE148_SUITE_SCRIPT" > "$STAGE148_LOG" 2>&1; then
    echo "cjgui stage149 semantic comparator bridge packet: stage148 suite failed" >&2
    echo "cjgui stage149 semantic comparator bridge packet: log=$STAGE148_LOG" >&2
    exit 8
  fi
  STAGE148_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE148_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE148_SUITE_PACKET" || ! -f "$STAGE148_SUITE_PACKET" ]]; then
  echo "cjgui stage149 semantic comparator bridge packet: missing stage148 suite packet" >&2
  exit 9
fi
for fact in \
  "stage148_baseline_fixture_bridge_after_stage145_first_slice_suite_passed=true" \
  "baseline_fixture_bridge_ready=true" \
  "baseline_fixture_source_contract_bound=true" \
  "semantic_comparator_source_contract_bound=true" \
  "baseline_fixture_bridge_runtime_admitted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE148_SUITE_PACKET" "$fact"
done

stage148_route="$(fact_value "$STAGE148_SUITE_PACKET" "baseline_fixture_bridge_route_classification")"
stage148_source_ready="$(fact_value "$STAGE148_SUITE_PACKET" "baseline_fixture_bridge_ready")"
stage145_runtime_input_ready="$(fact_value "$STAGE148_SUITE_PACKET" "stage145_baseline_semantic_runtime_input_ready")"
stage148_source_ready="${stage148_source_ready:-false}"
stage145_runtime_input_ready="${stage145_runtime_input_ready:-false}"

bridge_route="semantic_comparator_bridge_source_ready_runtime_blocked_missing_stage145_runtime_input"
if [[ "$stage148_route" == "baseline_fixture_bridge_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  bridge_route="semantic_comparator_bridge_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$stage145_runtime_input_ready" == "true" ]]; then
  bridge_route="semantic_comparator_bridge_source_ready_runtime_pending_live_compare"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage149 semantic comparator bridge packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage149_semantic_comparator_bridge_after_stage148_first_slice_packet_version=1"
  echo "stage148_input_mode=$stage148_input_mode"
  echo "stage148_suite_packet=$STAGE148_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage148_log=$STAGE148_LOG"
  echo "stage148_baseline_fixture_bridge_packet_consumed=true"
  echo "stage148_baseline_fixture_bridge_route_classification=$stage148_route"
  echo "stage145_baseline_semantic_runtime_input_ready=$stage145_runtime_input_ready"
  echo "semantic_comparator_bridge_ready=$stage148_source_ready"
  echo "semantic_comparator_bridge_source_ready=$stage148_source_ready"
  echo "semantic_comparator_bridge_runtime_admitted=false"
  echo "semantic_comparator_bridge_route_classification=$bridge_route"
  echo "semantic_comparator_bridge_missing_predicates=live_stage145_runtime_input,live_baseline_compare,backend_ready_truth"
  echo "semantic_comparator_bridge_source_only=true"
  echo "semantic_comparison_positive_fixture_matched=$(fact_value "$STAGE148_SUITE_PACKET" "legacy_semantic_comparison_positive_fixture_matched")"
  echo "semantic_comparison_negative_fixture_rejected=$(fact_value "$STAGE148_SUITE_PACKET" "legacy_semantic_comparison_negative_fixture_rejected")"
  echo "semantic_acceptance_source_comparison_admitted=true"
  echo "semantic_acceptance_runtime_admitted=false"
  echo "baseline_comparison_executed=false"
  echo "baseline_compared=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_truth_recheck_after_semantic_comparator_bridge"
  echo "stage149_semantic_comparator_bridge_after_stage148_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage149 semantic comparator bridge packet: route_classification=$bridge_route"
echo "cjgui stage149 semantic comparator bridge packet: semantic_comparator_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage149 semantic comparator bridge packet: renderer_state_write=false"
