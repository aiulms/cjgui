#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage169 owner-local state envelope dry-run packet，
# 消费 stage168 admission snapshot suite packet，并输出 stage170 executor 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE169_PACKET_TMPDIR:-/tmp/cjgui-stage169-owner-local-state-envelope-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage169_owner_local_state_envelope_dry_run_first_slice_owner.sh"
STAGE168_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage168_renderer_state_write_admission_snapshot_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE168_LOG="$TMP_DIR/stage168.log"
RESULT_PACKET="$TMP_DIR/stage169-owner-local-state-envelope-dry-run-first-slice.packet"
STAGE168_SUITE_PACKET="${CJGUI_STAGE168_RENDERER_STATE_WRITE_ADMISSION_SNAPSHOT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage168"
: > "$OWNER_LOG"
: > "$STAGE168_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE168_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage169 owner-local state envelope dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage169 owner-local state envelope dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage169 owner-local state envelope dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage169 owner-local state envelope dry-run packet: owner probe failed" >&2
  echo "cjgui stage169 owner-local state envelope dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage169_owner_local_state_envelope_dry_run_owner_present=true" \
  "stage168_renderer_state_write_admission_snapshot_required=true" \
  "owner_local_renderer_state_envelope_dry_run_materialized=true" \
  "admission_snapshot_to_owner_local_envelope_bound=true" \
  "rollback_shadow_state_envelope_bound=true" \
  "stage170_guarded_state_write_executor_input_prepared=true" \
  "owner_local_state_envelope_dry_run_ready=true" \
  "owner_local_state_envelope_dry_run_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage168_input_mode="generated_stage168_suite_packet"
if [[ -n "$STAGE168_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE168_SUITE_PACKET" ]]; then
    echo "cjgui stage169 owner-local state envelope dry-run packet: provided stage168 suite packet missing $STAGE168_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage168_suite_packet_used=true" > "$STAGE168_LOG"
  stage168_input_mode="provided_stage168_suite_packet"
else
  if ! env CJGUI_STAGE168_TMPDIR="$TMP_DIR/stage168" zsh "$STAGE168_SUITE_SCRIPT" > "$STAGE168_LOG" 2>&1; then
    echo "cjgui stage169 owner-local state envelope dry-run packet: stage168 suite failed" >&2
    echo "cjgui stage169 owner-local state envelope dry-run packet: log=$STAGE168_LOG" >&2
    exit 8
  fi
  STAGE168_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE168_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE168_SUITE_PACKET" || ! -f "$STAGE168_SUITE_PACKET" ]]; then
  echo "cjgui stage169 owner-local state envelope dry-run packet: missing stage168 suite packet" >&2
  exit 9
fi
for fact in \
  "stage168_renderer_state_write_admission_snapshot_suite_passed=true" \
  "renderer_state_write_admission_snapshot_ready=true" \
  "renderer_state_write_admission_snapshot_source_ready=true" \
  "renderer_state_write_admission_snapshot_runtime_admitted=false" \
  "stage169_owner_local_state_envelope_dry_run_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE168_SUITE_PACKET" "$fact"
done

stage168_route="$(fact_value "$STAGE168_SUITE_PACKET" "renderer_state_write_admission_snapshot_route_classification")"
stage168_runtime_admitted="$(fact_value "$STAGE168_SUITE_PACKET" "renderer_state_write_admission_snapshot_runtime_admitted")"
stage168_runtime_admitted="${stage168_runtime_admitted:-false}"
envelope_route="owner_local_state_envelope_dry_run_blocked_stage168_admission_snapshot"
if [[ "$stage168_route" == *"host_metal_device_unavailable" ]]; then
  envelope_route="owner_local_state_envelope_dry_run_blocked_host_metal_device_unavailable"
elif [[ "$stage168_runtime_admitted" == "true" ]]; then
  envelope_route="owner_local_state_envelope_dry_run_ready_for_guarded_state_write_executor"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage169 owner-local state envelope dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage169_owner_local_state_envelope_dry_run_packet_version=1"
  echo "stage168_input_mode=$stage168_input_mode"
  echo "stage168_suite_packet=$STAGE168_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage168_log=$STAGE168_LOG"
  echo "stage168_renderer_state_write_admission_snapshot_consumed=true"
  echo "stage168_renderer_state_write_admission_snapshot_route_classification=$stage168_route"
  echo "stage168_renderer_state_write_admission_snapshot_runtime_admitted=$stage168_runtime_admitted"
  echo "owner_local_state_envelope_dry_run_route_classification=$envelope_route"
  echo "owner_local_state_envelope_dry_run_ready=true"
  echo "owner_local_state_envelope_dry_run_source_ready=true"
  echo "owner_local_state_envelope_dry_run_runtime_admitted=false"
  echo "owner_local_renderer_state_envelope_dry_run_materialized=true"
  echo "admission_snapshot_to_owner_local_envelope_bound=true"
  echo "rollback_shadow_state_envelope_bound=true"
  echo "visibility_shadow_state_envelope_bound=true"
  echo "owner_local_state_envelope_dry_run_non_mutating=true"
  echo "renderer_state_write_first_slice_candidate_materialized=true"
  echo "stage170_guarded_state_write_executor_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage170_guarded_state_write_executor_first_slice_after_owner_local_envelope"
  echo "stage169_owner_local_state_envelope_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage169 owner-local state envelope dry-run packet: route_classification=$envelope_route"
echo "cjgui stage169 owner-local state envelope dry-run packet: owner_local_state_envelope_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage169 owner-local state envelope dry-run packet: renderer_state_write=false"
