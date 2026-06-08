#!/usr/bin/env zsh
#
# Focused suite for stage813. It consumes stage812 and records the minimal
# owner-local commit first-slice preflight shape.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE813_TMPDIR:-/private/tmp/cjgui-stage813-stage816/stage813}"
SUITE_PACKET="$TMP_DIR/stage813-preview-component-api-state-store-commit-first-slice-preflight-suite.packet"
STAGE812_SUITE_PACKET="${CJGUI_STAGE813_INPUT_PACKET:-${CJGUI_STAGE812_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_ACCEPTANCE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage809-stage812/stage812/stage812-preview-component-api-state-store-commit-acceptance-runtime-manager-suite.packet}}"
STAGE812_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage813-preview-component-api-state-store-commit-first-slice-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage813 preview component api state-store commit first-slice preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE812_SUITE_PACKET" ]] || ! grep -F "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_suite_passed=true" "$STAGE812_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE812_TMPDIR="$TMP_DIR/stage812" zsh "$STAGE812_SUITE_SCRIPT" >/dev/null
  STAGE812_SUITE_PACKET="$TMP_DIR/stage812/stage812-preview-component-api-state-store-commit-acceptance-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_consumed=true" \
  "commit_first_slice_slot_allowlist_materialized=true" \
  "owner_local_write_set_candidate_shape_materialized=true" \
  "rollback_snapshot_policy_materialized=true" \
  "commit_compatibility_gate_materialized=true" \
  "not_published_commit_boundary_materialized=true" \
  "first_slice_preflight_bound_to_acceptance_runtime_manager=true" \
  "first_slice_preflight_non_public=true" \
  "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_prepared=true" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_suite_passed=true" \
  "shared_acceptance_rehearsal_runtime_manager_materialized=true" \
  "stage813_preview_component_api_state_store_commit_first_slice_preflight_prepared=true"; do
  require_file_fact "$STAGE812_SUITE_PACKET" "$fact"
done

{
  echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_suite_version=1"
  echo "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_suite_packet=$STAGE812_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage813 preview component api state-store commit first-slice preflight suite: route_classification=state_store_commit_first_slice_preflight"
echo "cjgui stage813 preview component api state-store commit first-slice preflight suite: suite_packet_path=$SUITE_PACKET"
