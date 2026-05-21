#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage184 owner-local state envelope packet，
# 消费 stage183 final admission recheck suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE184_PACKET_TMPDIR:-/tmp/cjgui-stage184-owner-local-state-envelope-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage184_renderer_state_write_owner_local_state_envelope_first_slice_owner.sh"
STAGE183_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage183_renderer_state_write_final_admission_recheck_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE183_LOG="$TMP_DIR/stage183.log"
RESULT_PACKET="$TMP_DIR/stage184-renderer-state-write-owner-local-state-envelope-first-slice.packet"
STAGE183_SUITE_PACKET="${CJGUI_STAGE183_FINAL_ADMISSION_RECHECK_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage183"
: > "$OWNER_LOG"
: > "$STAGE183_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE183_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage184 owner-local state envelope packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage184 owner-local state envelope packet: syntax check failed $script" >&2
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
    echo "cjgui stage184 owner-local state envelope packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage184 owner-local state envelope packet: owner probe failed" >&2
  echo "cjgui stage184 owner-local state envelope packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage184_owner_local_state_envelope_owner_present=true" \
  "stage183_final_admission_recheck_required=true" \
  "renderer_state_write_owner_local_state_envelope_materialized=true" \
  "final_admission_ledger_to_state_envelope_bound=true" \
  "blocked_write_decision_to_envelope_bound=true" \
  "rollback_visibility_boundary_to_envelope_bound=true" \
  "stage185_runtime_state_write_schema_candidate_input_prepared=true" \
  "owner_local_state_envelope_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage183_input_mode="generated_stage183_suite_packet"
if [[ -n "$STAGE183_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE183_SUITE_PACKET" ]]; then
    echo "cjgui stage184 owner-local state envelope packet: provided stage183 suite packet missing $STAGE183_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage183_suite_packet_used=true" > "$STAGE183_LOG"
  stage183_input_mode="provided_stage183_suite_packet"
else
  if ! env CJGUI_STAGE183_TMPDIR="$TMP_DIR/stage183" zsh "$STAGE183_SUITE_SCRIPT" > "$STAGE183_LOG" 2>&1; then
    echo "cjgui stage184 owner-local state envelope packet: stage183 suite failed" >&2
    echo "cjgui stage184 owner-local state envelope packet: log=$STAGE183_LOG" >&2
    exit 8
  fi
  STAGE183_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE183_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE183_SUITE_PACKET" || ! -f "$STAGE183_SUITE_PACKET" ]]; then
  echo "cjgui stage184 owner-local state envelope packet: missing stage183 suite packet" >&2
  exit 9
fi
for fact in \
  "stage183_final_admission_recheck_suite_passed=true" \
  "renderer_state_write_final_admission_recheck_ready=true" \
  "renderer_state_write_final_admission_recheck_source_ready=true" \
  "renderer_state_write_final_admission_recheck_runtime_admitted=false" \
  "renderer_state_write_final_admission_ledger_materialized=true" \
  "renderer_state_write_final_admission_denied=true" \
  "stage184_renderer_state_write_owner_local_state_envelope_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE183_SUITE_PACKET" "$fact"
done

stage183_route="$(fact_value "$STAGE183_SUITE_PACKET" "renderer_state_write_final_admission_recheck_route_classification")"
stage183_runtime_admitted="$(fact_value "$STAGE183_SUITE_PACKET" "renderer_state_write_final_admission_recheck_runtime_admitted")"
stage183_runtime_admitted="${stage183_runtime_admitted:-false}"
state_envelope_route="renderer_state_write_owner_local_state_envelope_ready_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage184 owner-local state envelope packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage184_owner_local_state_envelope_packet_version=1"
  echo "stage183_input_mode=$stage183_input_mode"
  echo "stage183_suite_packet=$STAGE183_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage183_log=$STAGE183_LOG"
  echo "stage183_final_admission_recheck_consumed=true"
  echo "stage183_final_admission_recheck_route_classification=$stage183_route"
  echo "stage183_final_admission_recheck_runtime_admitted=$stage183_runtime_admitted"
  echo "renderer_state_write_owner_local_state_envelope_route_classification=$state_envelope_route"
  echo "renderer_state_write_owner_local_state_envelope_ready=true"
  echo "renderer_state_write_owner_local_state_envelope_source_ready=true"
  echo "renderer_state_write_owner_local_state_envelope_runtime_admitted=false"
  echo "renderer_state_write_owner_local_state_envelope_materialized=true"
  echo "final_admission_ledger_to_state_envelope_bound=true"
  echo "blocked_write_decision_to_envelope_bound=true"
  echo "rollback_visibility_boundary_to_envelope_bound=true"
  echo "owner_local_state_envelope_dry_run_only=true"
  echo "renderer_state_write_eligibility=false"
  echo "stage185_runtime_state_write_schema_candidate_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage185_runtime_state_write_schema_candidate_after_owner_local_state_envelope"
  echo "stage184_owner_local_state_envelope_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage184 owner-local state envelope packet: route_classification=$state_envelope_route"
echo "cjgui stage184 owner-local state envelope packet: owner_local_state_envelope_packet_path=$RESULT_PACKET"
echo "cjgui stage184 owner-local state envelope packet: renderer_state_write=false"
