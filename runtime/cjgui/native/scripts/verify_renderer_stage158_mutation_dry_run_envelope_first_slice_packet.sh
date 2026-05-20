#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage158 mutation dry-run envelope packet。它消费
# stage157 packet，输出 guarded executor dry-run 输入证据，但不执行写入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE158_PACKET_TMPDIR:-/tmp/cjgui-stage158-mutation-dry-run-envelope-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage158_mutation_dry_run_envelope_first_slice_owner.sh"
STAGE157_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage157_internal_owner_envelope_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE157_LOG="$TMP_DIR/stage157.log"
RESULT_PACKET="$TMP_DIR/stage158-mutation-dry-run-envelope-first-slice.packet"
STAGE157_SUITE_PACKET="${CJGUI_STAGE157_INTERNAL_OWNER_ENVELOPE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage157"
: > "$OWNER_LOG"
: > "$STAGE157_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE157_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage158 mutation dry-run envelope packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage158 mutation dry-run envelope packet: syntax check failed $script" >&2
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
    echo "cjgui stage158 mutation dry-run envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage158 mutation dry-run envelope packet: owner probe failed" >&2
  echo "cjgui stage158 mutation dry-run envelope packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage158_mutation_dry_run_envelope_owner_present=true" \
  "stage157_internal_owner_envelope_required=true" \
  "mutation_dry_run_envelope_materialized=true" \
  "executable_mutation_dry_run_shape_defined=true" \
  "guarded_executor_dry_run_input_prepared=true" \
  "mutation_dry_run_envelope_ready=true" \
  "mutation_dry_run_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage157_input_mode="generated_stage157_suite_packet"
if [[ -n "$STAGE157_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE157_SUITE_PACKET" ]]; then
    echo "cjgui stage158 mutation dry-run envelope packet: provided stage157 suite packet missing $STAGE157_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage157_suite_packet_used=true" > "$STAGE157_LOG"
  stage157_input_mode="provided_stage157_suite_packet"
else
  if ! env CJGUI_STAGE157_TMPDIR="$TMP_DIR/stage157" zsh "$STAGE157_SUITE_SCRIPT" > "$STAGE157_LOG" 2>&1; then
    echo "cjgui stage158 mutation dry-run envelope packet: stage157 suite failed" >&2
    echo "cjgui stage158 mutation dry-run envelope packet: log=$STAGE157_LOG" >&2
    exit 8
  fi
  STAGE157_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE157_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE157_SUITE_PACKET" || ! -f "$STAGE157_SUITE_PACKET" ]]; then
  echo "cjgui stage158 mutation dry-run envelope packet: missing stage157 suite packet" >&2
  exit 9
fi
for fact in \
  "stage157_internal_owner_envelope_suite_passed=true" \
  "internal_owner_envelope_ready=true" \
  "internal_owner_envelope_source_ready=true" \
  "internal_owner_envelope_runtime_admitted=false" \
  "owner_local_renderer_state_envelope_materialized=true" \
  "owner_local_result_shapes_prepared=true" \
  "mutation_dry_run_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE157_SUITE_PACKET" "$fact"
done

stage157_route="$(fact_value "$STAGE157_SUITE_PACKET" "internal_owner_envelope_route_classification")"
stage157_runtime_admitted="$(fact_value "$STAGE157_SUITE_PACKET" "internal_owner_envelope_runtime_admitted")"
stage157_runtime_admitted="${stage157_runtime_admitted:-false}"
dry_run_route="mutation_dry_run_blocked_stage157_runtime_admission"
if [[ "$stage157_route" == "internal_owner_envelope_blocked_host_metal_device_unavailable" ]]; then
  dry_run_route="mutation_dry_run_blocked_host_metal_device_unavailable"
elif [[ "$stage157_runtime_admitted" == "true" ]]; then
  dry_run_route="mutation_dry_run_ready_for_guarded_executor_bridge"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage158 mutation dry-run envelope packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage158_mutation_dry_run_envelope_packet_version=1"
  echo "stage157_input_mode=$stage157_input_mode"
  echo "stage157_suite_packet=$STAGE157_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage157_log=$STAGE157_LOG"
  echo "stage157_internal_owner_envelope_consumed=true"
  echo "stage157_internal_owner_envelope_route_classification=$stage157_route"
  echo "stage157_internal_owner_envelope_runtime_admitted=$stage157_runtime_admitted"
  echo "mutation_dry_run_route_classification=$dry_run_route"
  echo "mutation_dry_run_envelope_ready=true"
  echo "mutation_dry_run_source_ready=true"
  echo "mutation_dry_run_runtime_admitted=false"
  echo "mutation_dry_run_envelope_materialized=true"
  echo "executable_mutation_dry_run_shape_defined=true"
  echo "owner_local_envelope_bound_to_mutation_request=true"
  echo "guarded_executor_dry_run_input_prepared=true"
  echo "visibility_result_bridge_input_prepared=true"
  echo "renderer_state_write_first_slice_predicates_satisfied=false"
  echo "renderer_state_write_first_slice_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage159_visibility_result_bridge_after_stage158"
  echo "stage158_mutation_dry_run_envelope_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage158 mutation dry-run envelope packet: route_classification=$dry_run_route"
echo "cjgui stage158 mutation dry-run envelope packet: mutation_dry_run_envelope_packet_path=$RESULT_PACKET"
echo "cjgui stage158 mutation dry-run envelope packet: renderer_state_write=false"
