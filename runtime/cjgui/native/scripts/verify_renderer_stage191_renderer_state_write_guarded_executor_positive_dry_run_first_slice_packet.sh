#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage191 guarded executor positive dry-run packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE191_PACKET_TMPDIR:-/tmp/cjgui-stage191-renderer-state-guarded-executor-positive-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage191_renderer_state_write_guarded_executor_positive_dry_run_first_slice_owner.sh"
STAGE190_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage190_renderer_state_write_positive_predicate_fixture_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE190_LOG="$TMP_DIR/stage190.log"
RESULT_PACKET="$TMP_DIR/stage191-renderer-state-write-guarded-executor-positive-dry-run-first-slice.packet"
STAGE190_SUITE_PACKET="${CJGUI_STAGE190_RENDERER_STATE_WRITE_POSITIVE_PREDICATE_FIXTURE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage190"
: > "$OWNER_LOG"
: > "$STAGE190_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE190_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: owner probe failed" >&2
  echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage191_renderer_state_guarded_executor_positive_dry_run_owner_present=true" \
  "stage190_renderer_state_positive_predicate_fixture_required=true" \
  "renderer_state_write_guarded_executor_positive_dry_run_materialized=true" \
  "positive_fixture_to_guarded_executor_dry_run_bound=true" \
  "owner_local_mutation_candidate_envelope_materialized=true" \
  "rollback_snapshot_placeholder_materialized=true" \
  "fixture_guarded_executor_predicates_satisfied=true" \
  "stage192_renderer_state_write_visibility_publication_positive_dry_run_input_prepared=true" \
  "guarded_executor_positive_dry_run_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage190_input_mode="generated_stage190_suite_packet"
if [[ -n "$STAGE190_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE190_SUITE_PACKET" ]]; then
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: provided stage190 suite packet missing $STAGE190_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage190_suite_packet_used=true" > "$STAGE190_LOG"
  stage190_input_mode="provided_stage190_suite_packet"
else
  if ! env CJGUI_STAGE190_TMPDIR="$TMP_DIR/stage190" zsh "$STAGE190_SUITE_SCRIPT" > "$STAGE190_LOG" 2>&1; then
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: stage190 suite failed" >&2
    echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: log=$STAGE190_LOG" >&2
    exit 8
  fi
  STAGE190_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE190_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE190_SUITE_PACKET" || ! -f "$STAGE190_SUITE_PACKET" ]]; then
  echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: missing stage190 suite packet" >&2
  exit 9
fi
for fact in \
  "stage190_renderer_state_positive_predicate_fixture_suite_passed=true" \
  "renderer_state_write_positive_predicate_fixture_ready=true" \
  "positive_fixture_all_predicates_positive=true" \
  "positive_predicate_fixture_non_production=true" \
  "stage191_renderer_state_write_guarded_executor_positive_dry_run_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE190_SUITE_PACKET" "$fact"
done

stage190_route="$(fact_value "$STAGE190_SUITE_PACKET" "renderer_state_write_positive_predicate_fixture_route_classification")"
stage191_route="renderer_state_write_guarded_executor_positive_dry_run_ready_fixture_only_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage191_renderer_state_write_guarded_executor_positive_dry_run_packet_version=1"
  echo "stage190_input_mode=$stage190_input_mode"
  echo "stage190_suite_packet=$STAGE190_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage190_log=$STAGE190_LOG"
  echo "stage190_renderer_state_positive_predicate_fixture_consumed=true"
  echo "stage190_renderer_state_positive_predicate_fixture_route_classification=$stage190_route"
  echo "renderer_state_write_guarded_executor_positive_dry_run_route_classification=$stage191_route"
  echo "renderer_state_write_guarded_executor_positive_dry_run_ready=true"
  echo "renderer_state_write_guarded_executor_positive_dry_run_source_ready=true"
  echo "renderer_state_write_guarded_executor_positive_dry_run_runtime_admitted=false"
  echo "renderer_state_write_guarded_executor_positive_dry_run_materialized=true"
  echo "positive_fixture_to_guarded_executor_dry_run_bound=true"
  echo "owner_local_mutation_candidate_envelope_materialized=true"
  echo "rollback_snapshot_placeholder_materialized=true"
  echo "fixture_guarded_executor_predicates_satisfied=true"
  echo "guarded_executor_positive_dry_run_non_mutating=true"
  echo "stage192_renderer_state_write_visibility_publication_positive_dry_run_input_prepared=true"
  echo "positive_fixture_all_predicates_positive=true"
  echo "positive_predicate_fixture_non_production=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "renderer_state_write_eligibility=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage192_renderer_state_write_visibility_publication_positive_dry_run_after_guarded_executor"
  echo "stage191_renderer_state_guarded_executor_positive_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: route_classification=$stage191_route"
echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: guarded_executor_positive_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage191 renderer_state guarded executor positive dry-run packet: runtime_state_write=false"
