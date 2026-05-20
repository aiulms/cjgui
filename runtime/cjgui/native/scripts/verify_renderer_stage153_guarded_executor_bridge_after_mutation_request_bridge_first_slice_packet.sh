#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage153 guarded executor bridge packet。它消费
# stage152 mutation request bridge 与 legacy guarded executor result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE153_PACKET_TMPDIR:-/tmp/cjgui-stage153-guarded-executor-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_owner.sh"
STAGE152_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage152_mutation_request_bridge_after_write_token_gate_first_slice_suite.sh"
GUARDED_RESULT_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE152_LOG="$TMP_DIR/stage152.log"
GUARDED_RESULT_LOG="$TMP_DIR/guarded-result.log"
RESULT_PACKET="$TMP_DIR/stage153-guarded-executor-bridge-after-mutation-request-bridge.packet"
STAGE152_SUITE_PACKET="${CJGUI_STAGE152_MUTATION_REQUEST_BRIDGE_SUITE_PACKET:-}"
GUARDED_RESULT_SUITE_PACKET="${CJGUI_STAGE127_GUARDED_RESULT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage152" "$TMP_DIR/guarded-result"
: > "$OWNER_LOG"
: > "$STAGE152_LOG"
: > "$GUARDED_RESULT_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE152_SUITE_SCRIPT" "$GUARDED_RESULT_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage153 guarded executor bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage153 guarded executor bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage153 guarded executor bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage153 guarded executor bridge packet: owner probe failed" >&2
  echo "cjgui stage153 guarded executor bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage153_guarded_executor_bridge_after_mutation_request_bridge_owner_present=true" \
  "stage152_mutation_request_bridge_packet_required=true" \
  "legacy_guarded_executor_result_envelope_required=true" \
  "guarded_executor_denial_bound_to_stage152_bridge=true" \
  "visibility_publication_denial_input_prepared=true" \
  "guarded_executor_bridge_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage152_input_mode="generated_stage152_suite_packet"
if [[ -n "$STAGE152_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE152_SUITE_PACKET" ]]; then
    echo "cjgui stage153 guarded executor bridge packet: provided stage152 suite packet missing $STAGE152_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage152_suite_packet_used=true" > "$STAGE152_LOG"
  stage152_input_mode="provided_stage152_suite_packet"
else
  if ! env CJGUI_STAGE152_TMPDIR="$TMP_DIR/stage152" zsh "$STAGE152_SUITE_SCRIPT" > "$STAGE152_LOG" 2>&1; then
    echo "cjgui stage153 guarded executor bridge packet: stage152 suite failed" >&2
    echo "cjgui stage153 guarded executor bridge packet: log=$STAGE152_LOG" >&2
    exit 8
  fi
  STAGE152_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE152_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE152_SUITE_PACKET" || ! -f "$STAGE152_SUITE_PACKET" ]]; then
  echo "cjgui stage153 guarded executor bridge packet: missing stage152 suite packet" >&2
  exit 9
fi
for fact in \
  "stage152_mutation_request_bridge_after_write_token_gate_first_slice_suite_passed=true" \
  "mutation_request_bridge_ready=true" \
  "mutation_request_bridge_source_ready=true" \
  "mutation_request_bridge_runtime_admitted=false" \
  "guarded_state_write_executor_bridge_input_prepared=true" \
  "guarded_state_write_executor_blocked=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE152_SUITE_PACKET" "$fact"
done

guarded_result_input_mode="generated_legacy_guarded_result_suite_packet"
if [[ -n "$GUARDED_RESULT_SUITE_PACKET" ]]; then
  if [[ ! -f "$GUARDED_RESULT_SUITE_PACKET" ]]; then
    echo "cjgui stage153 guarded executor bridge packet: provided guarded result suite packet missing $GUARDED_RESULT_SUITE_PACKET" >&2
    exit 10
  fi
  echo "provided_guarded_result_suite_packet_used=true" > "$GUARDED_RESULT_LOG"
  guarded_result_input_mode="provided_legacy_guarded_result_suite_packet"
else
  if ! env CJGUI_STAGE127_TMPDIR="$TMP_DIR/guarded-result" zsh "$GUARDED_RESULT_SUITE_SCRIPT" > "$GUARDED_RESULT_LOG" 2>&1; then
    echo "cjgui stage153 guarded executor bridge packet: guarded result suite failed" >&2
    echo "cjgui stage153 guarded executor bridge packet: log=$GUARDED_RESULT_LOG" >&2
    exit 11
  fi
  GUARDED_RESULT_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$GUARDED_RESULT_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$GUARDED_RESULT_SUITE_PACKET" || ! -f "$GUARDED_RESULT_SUITE_PACKET" ]]; then
  echo "cjgui stage153 guarded executor bridge packet: missing guarded result suite packet" >&2
  exit 12
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite_passed=true" \
  "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true" \
  "guarded_state_write_executor_result_envelope_materialized=true" \
  "guarded_executor_denial_persisted_as_dry_run_fact=true" \
  "rollback_stop_line_persisted_as_dry_run_fact=true" \
  "visibility_publication_denial_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "guarded_state_write_executor_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$GUARDED_RESULT_SUITE_PACKET" "$fact"
done

stage152_route="$(fact_value "$STAGE152_SUITE_PACKET" "mutation_request_bridge_route_classification")"
mutation_request_bridge_runtime_admitted="$(fact_value "$STAGE152_SUITE_PACKET" "mutation_request_bridge_runtime_admitted")"
mutation_request_bridge_runtime_admitted="${mutation_request_bridge_runtime_admitted:-false}"
guarded_bridge_route="guarded_executor_bridge_source_ready_runtime_blocked_mutation_request_bridge"
if [[ "$stage152_route" == "mutation_request_bridge_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  guarded_bridge_route="guarded_executor_bridge_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$mutation_request_bridge_runtime_admitted" == "true" ]]; then
  guarded_bridge_route="guarded_executor_bridge_source_ready_runtime_blocked_guarded_executor_denied"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage153 guarded executor bridge packet: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_packet_version=1"
  echo "stage152_input_mode=$stage152_input_mode"
  echo "guarded_result_input_mode=$guarded_result_input_mode"
  echo "stage152_suite_packet=$STAGE152_SUITE_PACKET"
  echo "legacy_guarded_result_suite_packet=$GUARDED_RESULT_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage152_log=$STAGE152_LOG"
  echo "guarded_result_log=$GUARDED_RESULT_LOG"
  echo "stage152_mutation_request_bridge_packet_consumed=true"
  echo "legacy_guarded_executor_result_envelope_consumed=true"
  echo "stage152_mutation_request_bridge_route_classification=$stage152_route"
  echo "mutation_request_bridge_runtime_admitted=$mutation_request_bridge_runtime_admitted"
  echo "guarded_executor_bridge_ready=true"
  echo "guarded_executor_bridge_source_ready=true"
  echo "guarded_executor_bridge_runtime_admitted=false"
  echo "guarded_executor_bridge_route_classification=$guarded_bridge_route"
  echo "guarded_executor_inputs_bound_to_stage152_bridge=true"
  echo "guarded_executor_denial_bound_to_stage152_bridge=true"
  echo "rollback_stop_line_bound_to_stage152_bridge=true"
  echo "visibility_publication_denial_input_prepared=true"
  echo "visibility_publication_blocked=true"
  echo "guarded_executor_denied=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=visibility_publication_denial_after_guarded_executor_bridge_or_metal_capable_rerun"
  echo "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage153 guarded executor bridge packet: route_classification=$guarded_bridge_route"
echo "cjgui stage153 guarded executor bridge packet: guarded_executor_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage153 guarded executor bridge packet: renderer_state_write=false"
