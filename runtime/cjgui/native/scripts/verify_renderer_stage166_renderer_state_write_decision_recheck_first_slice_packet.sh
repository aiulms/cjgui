#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage166 write-decision recheck packet，消费 stage165
# visibility publication suite packet 并输出 state-write first-slice 前置合同。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE166_PACKET_TMPDIR:-/tmp/cjgui-stage166-renderer-state-write-decision-recheck-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage166_renderer_state_write_decision_recheck_first_slice_owner.sh"
STAGE165_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage165_renderer_state_write_visibility_publication_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE165_LOG="$TMP_DIR/stage165.log"
RESULT_PACKET="$TMP_DIR/stage166-renderer-state-write-decision-recheck-first-slice.packet"
STAGE165_SUITE_PACKET="${CJGUI_STAGE165_RENDERER_STATE_WRITE_VISIBILITY_PUBLICATION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage165"
: > "$OWNER_LOG"
: > "$STAGE165_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE165_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage166 renderer-state write decision recheck packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage166 renderer-state write decision recheck packet: syntax check failed $script" >&2
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
    echo "cjgui stage166 renderer-state write decision recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage166 renderer-state write decision recheck packet: owner probe failed" >&2
  echo "cjgui stage166 renderer-state write decision recheck packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage166_renderer_state_write_decision_recheck_owner_present=true" \
  "stage165_renderer_state_write_visibility_publication_required=true" \
  "renderer_state_write_decision_recheck_ledger_materialized=true" \
  "renderer_state_write_decision_positive_predicates_bound=true" \
  "renderer_state_write_first_slice_contract_input_prepared=true" \
  "renderer_state_write_decision_recheck_ready=true" \
  "renderer_state_write_decision_recheck_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage165_input_mode="generated_stage165_suite_packet"
if [[ -n "$STAGE165_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE165_SUITE_PACKET" ]]; then
    echo "cjgui stage166 renderer-state write decision recheck packet: provided stage165 suite packet missing $STAGE165_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage165_suite_packet_used=true" > "$STAGE165_LOG"
  stage165_input_mode="provided_stage165_suite_packet"
else
  if ! env CJGUI_STAGE165_TMPDIR="$TMP_DIR/stage165" zsh "$STAGE165_SUITE_SCRIPT" > "$STAGE165_LOG" 2>&1; then
    echo "cjgui stage166 renderer-state write decision recheck packet: stage165 suite failed" >&2
    echo "cjgui stage166 renderer-state write decision recheck packet: log=$STAGE165_LOG" >&2
    exit 8
  fi
  STAGE165_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE165_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE165_SUITE_PACKET" || ! -f "$STAGE165_SUITE_PACKET" ]]; then
  echo "cjgui stage166 renderer-state write decision recheck packet: missing stage165 suite packet" >&2
  exit 9
fi
for fact in \
  "stage165_renderer_state_write_visibility_publication_suite_passed=true" \
  "renderer_state_write_visibility_publication_ready=true" \
  "renderer_state_write_visibility_publication_source_ready=true" \
  "renderer_state_write_visibility_publication_runtime_admitted=false" \
  "renderer_state_write_decision_recheck_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE165_SUITE_PACKET" "$fact"
done

stage165_route="$(fact_value "$STAGE165_SUITE_PACKET" "renderer_state_write_visibility_publication_route_classification")"
stage165_runtime_admitted="$(fact_value "$STAGE165_SUITE_PACKET" "renderer_state_write_visibility_publication_runtime_admitted")"
stage165_runtime_admitted="${stage165_runtime_admitted:-false}"
decision_route="renderer_state_write_decision_recheck_blocked_stage165_runtime_admission"
if [[ "$stage165_route" == *"host_metal_device_unavailable" ]]; then
  decision_route="renderer_state_write_decision_recheck_blocked_host_metal_device_unavailable"
elif [[ "$stage165_runtime_admitted" == "true" ]]; then
  decision_route="renderer_state_write_decision_recheck_ready_for_state_write_first_slice_contract"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage166 renderer-state write decision recheck packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage166_renderer_state_write_decision_recheck_packet_version=1"
  echo "stage165_input_mode=$stage165_input_mode"
  echo "stage165_suite_packet=$STAGE165_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage165_log=$STAGE165_LOG"
  echo "stage165_renderer_state_write_visibility_publication_consumed=true"
  echo "stage165_renderer_state_write_visibility_publication_route_classification=$stage165_route"
  echo "stage165_renderer_state_write_visibility_publication_runtime_admitted=$stage165_runtime_admitted"
  echo "renderer_state_write_decision_recheck_route_classification=$decision_route"
  echo "renderer_state_write_decision_recheck_ready=true"
  echo "renderer_state_write_decision_recheck_source_ready=true"
  echo "renderer_state_write_decision_recheck_runtime_admitted=false"
  echo "renderer_state_write_decision_recheck_ledger_materialized=true"
  echo "renderer_state_write_decision_positive_predicates_bound=true"
  echo "renderer_state_write_first_slice_contract_input_prepared=true"
  echo "renderer_state_write_decision_denied=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage167_renderer_state_write_first_slice_contract_after_decision_recheck"
  echo "stage166_renderer_state_write_decision_recheck_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage166 renderer-state write decision recheck packet: route_classification=$decision_route"
echo "cjgui stage166 renderer-state write decision recheck packet: renderer_state_write_decision_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage166 renderer-state write decision recheck packet: renderer_state_write=false"
