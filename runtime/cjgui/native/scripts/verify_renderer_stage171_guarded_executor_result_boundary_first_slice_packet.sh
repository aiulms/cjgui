#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage171 guarded executor result boundary packet，
# 消费 stage170 guarded executor suite packet，并输出 stage172 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE171_PACKET_TMPDIR:-/tmp/cjgui-stage171-guarded-executor-result-boundary-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage171_guarded_executor_result_boundary_first_slice_owner.sh"
STAGE170_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage170_guarded_state_write_executor_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE170_LOG="$TMP_DIR/stage170.log"
RESULT_PACKET="$TMP_DIR/stage171-guarded-executor-result-boundary-first-slice.packet"
STAGE170_SUITE_PACKET="${CJGUI_STAGE170_GUARDED_STATE_WRITE_EXECUTOR_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage170"
: > "$OWNER_LOG"
: > "$STAGE170_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE170_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage171 guarded executor result boundary packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage171 guarded executor result boundary packet: syntax check failed $script" >&2
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
    echo "cjgui stage171 guarded executor result boundary packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage171 guarded executor result boundary packet: owner probe failed" >&2
  echo "cjgui stage171 guarded executor result boundary packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage171_guarded_executor_result_boundary_owner_present=true" \
  "stage170_guarded_state_write_executor_required=true" \
  "guarded_executor_result_boundary_envelope_materialized=true" \
  "guarded_executor_denial_reason_ledger_bound=true" \
  "rollback_eligibility_boundary_bound=true" \
  "stage172_visibility_publication_admission_input_prepared=true" \
  "guarded_executor_result_boundary_ready=true" \
  "guarded_executor_result_boundary_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage170_input_mode="generated_stage170_suite_packet"
if [[ -n "$STAGE170_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE170_SUITE_PACKET" ]]; then
    echo "cjgui stage171 guarded executor result boundary packet: provided stage170 suite packet missing $STAGE170_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage170_suite_packet_used=true" > "$STAGE170_LOG"
  stage170_input_mode="provided_stage170_suite_packet"
else
  if ! env CJGUI_STAGE170_TMPDIR="$TMP_DIR/stage170" zsh "$STAGE170_SUITE_SCRIPT" > "$STAGE170_LOG" 2>&1; then
    echo "cjgui stage171 guarded executor result boundary packet: stage170 suite failed" >&2
    echo "cjgui stage171 guarded executor result boundary packet: log=$STAGE170_LOG" >&2
    exit 8
  fi
  STAGE170_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE170_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE170_SUITE_PACKET" || ! -f "$STAGE170_SUITE_PACKET" ]]; then
  echo "cjgui stage171 guarded executor result boundary packet: missing stage170 suite packet" >&2
  exit 9
fi
for fact in \
  "stage170_guarded_state_write_executor_suite_passed=true" \
  "guarded_state_write_executor_ready=true" \
  "guarded_state_write_executor_source_ready=true" \
  "guarded_state_write_executor_runtime_admitted=false" \
  "stage171_guarded_executor_result_boundary_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE170_SUITE_PACKET" "$fact"
done

stage170_route="$(fact_value "$STAGE170_SUITE_PACKET" "guarded_state_write_executor_route_classification")"
stage170_runtime_admitted="$(fact_value "$STAGE170_SUITE_PACKET" "guarded_state_write_executor_runtime_admitted")"
stage170_runtime_admitted="${stage170_runtime_admitted:-false}"
boundary_route="guarded_executor_result_boundary_blocked_guarded_executor_admission"
if [[ "$stage170_route" == *"host_metal_device_unavailable" ]]; then
  boundary_route="guarded_executor_result_boundary_blocked_host_metal_device_unavailable"
elif [[ "$stage170_runtime_admitted" == "true" ]]; then
  boundary_route="guarded_executor_result_boundary_ready_for_visibility_publication_admission"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage171 guarded executor result boundary packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage171_guarded_executor_result_boundary_packet_version=1"
  echo "stage170_input_mode=$stage170_input_mode"
  echo "stage170_suite_packet=$STAGE170_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage170_log=$STAGE170_LOG"
  echo "stage170_guarded_state_write_executor_consumed=true"
  echo "stage170_guarded_state_write_executor_route_classification=$stage170_route"
  echo "stage170_guarded_state_write_executor_runtime_admitted=$stage170_runtime_admitted"
  echo "guarded_executor_result_boundary_route_classification=$boundary_route"
  echo "guarded_executor_result_boundary_ready=true"
  echo "guarded_executor_result_boundary_source_ready=true"
  echo "guarded_executor_result_boundary_runtime_admitted=false"
  echo "guarded_executor_result_boundary_envelope_materialized=true"
  echo "guarded_executor_denial_reason_ledger_bound=true"
  echo "rollback_eligibility_boundary_bound=true"
  echo "guarded_executor_result_boundary_non_mutating=true"
  echo "guarded_executor_result_boundary_predicates_satisfied=false"
  echo "stage172_visibility_publication_admission_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage172_visibility_publication_admission_after_guarded_executor_result_boundary"
  echo "stage171_guarded_executor_result_boundary_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage171 guarded executor result boundary packet: route_classification=$boundary_route"
echo "cjgui stage171 guarded executor result boundary packet: guarded_executor_result_boundary_packet_path=$RESULT_PACKET"
echo "cjgui stage171 guarded executor result boundary packet: renderer_state_write=false"
