#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage192 visibility publication positive dry-run packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE192_PACKET_TMPDIR:-/tmp/cjgui-stage192-renderer-state-visibility-publication-positive-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage192_renderer_state_write_visibility_publication_positive_dry_run_first_slice_owner.sh"
STAGE191_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage191_renderer_state_write_guarded_executor_positive_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE191_LOG="$TMP_DIR/stage191.log"
RESULT_PACKET="$TMP_DIR/stage192-renderer-state-write-visibility-publication-positive-dry-run-first-slice.packet"
STAGE191_SUITE_PACKET="${CJGUI_STAGE191_RENDERER_STATE_WRITE_GUARDED_EXECUTOR_POSITIVE_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage191"
: > "$OWNER_LOG"
: > "$STAGE191_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE191_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: owner probe failed" >&2
  echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage192_renderer_state_visibility_publication_positive_dry_run_owner_present=true" \
  "stage191_renderer_state_guarded_executor_positive_dry_run_required=true" \
  "renderer_state_write_visibility_publication_positive_dry_run_materialized=true" \
  "guarded_executor_positive_dry_run_to_visibility_publication_bound=true" \
  "visibility_publication_dry_run_receipt_materialized=true" \
  "non_public_visibility_publication_envelope_materialized=true" \
  "fixture_visibility_publication_admitted=true" \
  "stage193_renderer_state_write_first_slice_dry_run_executor_input_prepared=true" \
  "visibility_publication_positive_dry_run_internal_only=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage191_input_mode="generated_stage191_suite_packet"
if [[ -n "$STAGE191_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE191_SUITE_PACKET" ]]; then
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: provided stage191 suite packet missing $STAGE191_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage191_suite_packet_used=true" > "$STAGE191_LOG"
  stage191_input_mode="provided_stage191_suite_packet"
else
  if ! env CJGUI_STAGE191_TMPDIR="$TMP_DIR/stage191" zsh "$STAGE191_SUITE_SCRIPT" > "$STAGE191_LOG" 2>&1; then
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: stage191 suite failed" >&2
    echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: log=$STAGE191_LOG" >&2
    exit 8
  fi
  STAGE191_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE191_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE191_SUITE_PACKET" || ! -f "$STAGE191_SUITE_PACKET" ]]; then
  echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: missing stage191 suite packet" >&2
  exit 9
fi
for fact in \
  "stage191_renderer_state_guarded_executor_positive_dry_run_suite_passed=true" \
  "renderer_state_write_guarded_executor_positive_dry_run_ready=true" \
  "owner_local_mutation_candidate_envelope_materialized=true" \
  "rollback_snapshot_placeholder_materialized=true" \
  "fixture_guarded_executor_predicates_satisfied=true" \
  "stage192_renderer_state_write_visibility_publication_positive_dry_run_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE191_SUITE_PACKET" "$fact"
done

stage191_route="$(fact_value "$STAGE191_SUITE_PACKET" "renderer_state_write_guarded_executor_positive_dry_run_route_classification")"
stage192_route="renderer_state_write_visibility_publication_positive_dry_run_ready_fixture_only_write_blocked"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage192_renderer_state_write_visibility_publication_positive_dry_run_packet_version=1"
  echo "stage191_input_mode=$stage191_input_mode"
  echo "stage191_suite_packet=$STAGE191_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage191_log=$STAGE191_LOG"
  echo "stage191_renderer_state_guarded_executor_positive_dry_run_consumed=true"
  echo "stage191_renderer_state_guarded_executor_positive_dry_run_route_classification=$stage191_route"
  echo "renderer_state_write_visibility_publication_positive_dry_run_route_classification=$stage192_route"
  echo "renderer_state_write_visibility_publication_positive_dry_run_ready=true"
  echo "renderer_state_write_visibility_publication_positive_dry_run_source_ready=true"
  echo "renderer_state_write_visibility_publication_positive_dry_run_runtime_admitted=false"
  echo "renderer_state_write_visibility_publication_positive_dry_run_materialized=true"
  echo "guarded_executor_positive_dry_run_to_visibility_publication_bound=true"
  echo "visibility_publication_dry_run_receipt_materialized=true"
  echo "non_public_visibility_publication_envelope_materialized=true"
  echo "fixture_visibility_publication_admitted=true"
  echo "visibility_publication_positive_dry_run_internal_only=true"
  echo "stage193_renderer_state_write_first_slice_dry_run_executor_input_prepared=true"
  echo "positive_fixture_all_predicates_positive=true"
  echo "fixture_guarded_executor_predicates_satisfied=true"
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
  echo "next_route=stage193_renderer_state_write_first_slice_dry_run_executor_after_visibility_publication_positive_dry_run"
  echo "stage192_renderer_state_visibility_publication_positive_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: route_classification=$stage192_route"
echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: visibility_publication_positive_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage192 renderer_state visibility publication positive dry-run packet: runtime_state_write=false"
