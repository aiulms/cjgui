#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage188 runtime_state write visibility publication
# schema bridge packet，消费 stage187 guarded executor suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE188_PACKET_TMPDIR:-/tmp/cjgui-stage188-runtime-state-visibility-publication-schema-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage188_runtime_state_write_visibility_publication_schema_bridge_first_slice_owner.sh"
STAGE187_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage187_runtime_state_write_guarded_executor_schema_preflight_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE187_LOG="$TMP_DIR/stage187.log"
RESULT_PACKET="$TMP_DIR/stage188-runtime-state-write-visibility-publication-schema-bridge-first-slice.packet"
STAGE187_SUITE_PACKET="${CJGUI_STAGE187_RUNTIME_STATE_WRITE_GUARDED_EXECUTOR_SCHEMA_PREFLIGHT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage187"
: > "$OWNER_LOG"
: > "$STAGE187_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE187_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage188 runtime_state visibility publication schema bridge packet: owner probe failed" >&2
  echo "cjgui stage188 runtime_state visibility publication schema bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage188_runtime_state_visibility_publication_schema_bridge_owner_present=true" \
  "stage187_runtime_state_guarded_executor_schema_preflight_required=true" \
  "runtime_state_write_visibility_publication_schema_bridge_materialized=true" \
  "guarded_executor_preflight_to_visibility_publication_schema_bound=true" \
  "visibility_publication_schema_predicate_ledger_materialized=true" \
  "visibility_publication_hold_to_schema_bridge_bound=true" \
  "stage189_renderer_state_write_schema_readiness_recheck_input_prepared=true" \
  "visibility_publication_schema_bridge_internal_only=true" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage187_input_mode="generated_stage187_suite_packet"
if [[ -n "$STAGE187_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE187_SUITE_PACKET" ]]; then
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: provided stage187 suite packet missing $STAGE187_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage187_suite_packet_used=true" > "$STAGE187_LOG"
  stage187_input_mode="provided_stage187_suite_packet"
else
  if ! env CJGUI_STAGE187_TMPDIR="$TMP_DIR/stage187" zsh "$STAGE187_SUITE_SCRIPT" > "$STAGE187_LOG" 2>&1; then
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: stage187 suite failed" >&2
    echo "cjgui stage188 runtime_state visibility publication schema bridge packet: log=$STAGE187_LOG" >&2
    exit 8
  fi
  STAGE187_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE187_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE187_SUITE_PACKET" || ! -f "$STAGE187_SUITE_PACKET" ]]; then
  echo "cjgui stage188 runtime_state visibility publication schema bridge packet: missing stage187 suite packet" >&2
  exit 9
fi
for fact in \
  "stage187_runtime_state_guarded_executor_schema_preflight_suite_passed=true" \
  "runtime_state_write_guarded_executor_schema_preflight_ready=true" \
  "runtime_state_write_guarded_executor_predicate_recheck_materialized=true" \
  "rollback_visibility_hold_to_schema_preflight_bound=true" \
  "stage188_runtime_state_write_visibility_publication_schema_bridge_input_prepared=true" \
  "guarded_executor_schema_preflight_predicates_satisfied=false" \
  "renderer_state_write_eligibility=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE187_SUITE_PACKET" "$fact"
done

stage187_route="$(fact_value "$STAGE187_SUITE_PACKET" "runtime_state_write_guarded_executor_schema_preflight_route_classification")"
stage188_route="runtime_state_write_visibility_publication_schema_bridge_ready_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage188 runtime_state visibility publication schema bridge packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage188_runtime_state_visibility_publication_schema_bridge_packet_version=1"
  echo "stage187_input_mode=$stage187_input_mode"
  echo "stage187_suite_packet=$STAGE187_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage187_log=$STAGE187_LOG"
  echo "stage187_runtime_state_guarded_executor_schema_preflight_consumed=true"
  echo "stage187_runtime_state_guarded_executor_schema_preflight_route_classification=$stage187_route"
  echo "runtime_state_write_visibility_publication_schema_bridge_route_classification=$stage188_route"
  echo "runtime_state_write_visibility_publication_schema_bridge_ready=true"
  echo "runtime_state_write_visibility_publication_schema_bridge_source_ready=true"
  echo "runtime_state_write_visibility_publication_schema_bridge_runtime_admitted=false"
  echo "runtime_state_write_visibility_publication_schema_bridge_materialized=true"
  echo "guarded_executor_preflight_to_visibility_publication_schema_bound=true"
  echo "visibility_publication_schema_predicate_ledger_materialized=true"
  echo "visibility_publication_hold_to_schema_bridge_bound=true"
  echo "visibility_publication_schema_bridge_internal_only=true"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write_eligibility=false"
  echo "stage189_renderer_state_write_schema_readiness_recheck_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage189_renderer_state_write_schema_readiness_recheck_after_visibility_publication_schema_bridge"
  echo "stage188_runtime_state_visibility_publication_schema_bridge_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage188 runtime_state visibility publication schema bridge packet: route_classification=$stage188_route"
echo "cjgui stage188 runtime_state visibility publication schema bridge packet: visibility_publication_schema_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage188 runtime_state visibility publication schema bridge packet: runtime_state_write=false"
