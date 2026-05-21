#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage172 visibility publication admission packet，
# 消费 stage171 result boundary suite packet，并输出 stage173 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE172_PACKET_TMPDIR:-/tmp/cjgui-stage172-visibility-publication-admission-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage172_visibility_publication_admission_first_slice_owner.sh"
STAGE171_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage171_guarded_executor_result_boundary_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE171_LOG="$TMP_DIR/stage171.log"
RESULT_PACKET="$TMP_DIR/stage172-visibility-publication-admission-first-slice.packet"
STAGE171_SUITE_PACKET="${CJGUI_STAGE171_GUARDED_EXECUTOR_RESULT_BOUNDARY_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage171"
: > "$OWNER_LOG"
: > "$STAGE171_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE171_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage172 visibility publication admission packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage172 visibility publication admission packet: syntax check failed $script" >&2
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
    echo "cjgui stage172 visibility publication admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage172 visibility publication admission packet: owner probe failed" >&2
  echo "cjgui stage172 visibility publication admission packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage172_visibility_publication_admission_owner_present=true" \
  "stage171_guarded_executor_result_boundary_required=true" \
  "visibility_publication_admission_envelope_materialized=true" \
  "guarded_executor_boundary_to_visibility_admission_bound=true" \
  "rollback_eligibility_to_visibility_admission_bound=true" \
  "internal_visibility_publication_stop_line_bound=true" \
  "stage173_renderer_state_write_admission_readiness_input_prepared=true" \
  "visibility_publication_admission_ready=true" \
  "visibility_publication_admission_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage171_input_mode="generated_stage171_suite_packet"
if [[ -n "$STAGE171_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE171_SUITE_PACKET" ]]; then
    echo "cjgui stage172 visibility publication admission packet: provided stage171 suite packet missing $STAGE171_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage171_suite_packet_used=true" > "$STAGE171_LOG"
  stage171_input_mode="provided_stage171_suite_packet"
else
  if ! env CJGUI_STAGE171_TMPDIR="$TMP_DIR/stage171" zsh "$STAGE171_SUITE_SCRIPT" > "$STAGE171_LOG" 2>&1; then
    echo "cjgui stage172 visibility publication admission packet: stage171 suite failed" >&2
    echo "cjgui stage172 visibility publication admission packet: log=$STAGE171_LOG" >&2
    exit 8
  fi
  STAGE171_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE171_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE171_SUITE_PACKET" || ! -f "$STAGE171_SUITE_PACKET" ]]; then
  echo "cjgui stage172 visibility publication admission packet: missing stage171 suite packet" >&2
  exit 9
fi
for fact in \
  "stage171_guarded_executor_result_boundary_suite_passed=true" \
  "guarded_executor_result_boundary_ready=true" \
  "guarded_executor_result_boundary_source_ready=true" \
  "guarded_executor_result_boundary_runtime_admitted=false" \
  "stage172_visibility_publication_admission_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE171_SUITE_PACKET" "$fact"
done

stage171_route="$(fact_value "$STAGE171_SUITE_PACKET" "guarded_executor_result_boundary_route_classification")"
stage171_runtime_admitted="$(fact_value "$STAGE171_SUITE_PACKET" "guarded_executor_result_boundary_runtime_admitted")"
stage171_runtime_admitted="${stage171_runtime_admitted:-false}"
visibility_route="visibility_publication_admission_blocked_guarded_executor_boundary"
if [[ "$stage171_route" == *"host_metal_device_unavailable" ]]; then
  visibility_route="visibility_publication_admission_blocked_host_metal_device_unavailable"
elif [[ "$stage171_runtime_admitted" == "true" ]]; then
  visibility_route="visibility_publication_admission_ready_for_renderer_state_write_recheck"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage172 visibility publication admission packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage172_visibility_publication_admission_packet_version=1"
  echo "stage171_input_mode=$stage171_input_mode"
  echo "stage171_suite_packet=$STAGE171_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage171_log=$STAGE171_LOG"
  echo "stage171_guarded_executor_result_boundary_consumed=true"
  echo "stage171_guarded_executor_result_boundary_route_classification=$stage171_route"
  echo "stage171_guarded_executor_result_boundary_runtime_admitted=$stage171_runtime_admitted"
  echo "visibility_publication_admission_route_classification=$visibility_route"
  echo "visibility_publication_admission_ready=true"
  echo "visibility_publication_admission_source_ready=true"
  echo "visibility_publication_admission_runtime_admitted=false"
  echo "visibility_publication_admission_envelope_materialized=true"
  echo "guarded_executor_boundary_to_visibility_admission_bound=true"
  echo "rollback_eligibility_to_visibility_admission_bound=true"
  echo "internal_visibility_publication_stop_line_bound=true"
  echo "visibility_publication_admission_non_mutating=true"
  echo "visibility_publication_admission_predicates_satisfied=false"
  echo "stage173_renderer_state_write_admission_readiness_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage173_renderer_state_write_admission_readiness_recheck_after_visibility_publication_admission"
  echo "stage172_visibility_publication_admission_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage172 visibility publication admission packet: route_classification=$visibility_route"
echo "cjgui stage172 visibility publication admission packet: visibility_publication_admission_packet_path=$RESULT_PACKET"
echo "cjgui stage172 visibility publication admission packet: renderer_state_write=false"
