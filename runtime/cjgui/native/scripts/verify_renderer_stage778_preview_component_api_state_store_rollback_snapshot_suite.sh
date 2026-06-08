#!/usr/bin/env zsh
#
# Focused suite for stage778. It consumes stage777 and records rollback
# snapshot evidence for the preview component API state-store boundary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE778_TMPDIR:-/private/tmp/cjgui-stage777-stage780/stage778}"
SUITE_PACKET="$TMP_DIR/stage778-preview-component-api-state-store-rollback-snapshot-suite.packet"
STAGE777_SUITE_PACKET="${CJGUI_STAGE778_INPUT_PACKET:-${CJGUI_STAGE777_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_BOUNDARY_SUITE_PACKET:-/private/tmp/cjgui-stage777-stage780/stage777/stage777-preview-component-api-state-store-commit-boundary-suite.packet}}"
STAGE777_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage777_preview_component_api_state_store_commit_boundary_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage778_preview_component_api_state_store_rollback_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage778-preview-component-api-state-store-rollback-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage778 preview component api state-store rollback snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE777_SUITE_PACKET" ]] || ! grep -F "stage777_preview_component_api_state_store_commit_boundary_suite_passed=true" "$STAGE777_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE777_TMPDIR="$TMP_DIR/stage777" zsh "$STAGE777_SUITE_SCRIPT" >/dev/null
  STAGE777_SUITE_PACKET="$TMP_DIR/stage777/stage777-preview-component-api-state-store-commit-boundary-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage777_preview_component_api_state_store_commit_boundary_consumed=true" \
  "state_store_rollback_base_snapshot_materialized=true" \
  "state_store_pending_write_snapshot_materialized=true" \
  "state_store_conflict_version_ledger_materialized=true" \
  "state_store_rollback_token_ledger_materialized=true" \
  "chat_composer_preview_component_api_state_store_rollback_snapshot_surface_materialized=true" \
  "state_store_rollback_snapshot_bound_to_stage777_boundary=true" \
  "stage779_preview_component_api_state_store_not_published_host_surface_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage777_preview_component_api_state_store_commit_boundary_suite_passed=true" \
  "owner_local_state_store_write_set_candidate_materialized=true" \
  "state_store_commit_boundary_bound_to_stage776_runtime_manager=true"; do
  require_file_fact "$STAGE777_SUITE_PACKET" "$fact"
done

{
  echo "stage778_preview_component_api_state_store_rollback_snapshot_suite_version=1"
  echo "stage777_preview_component_api_state_store_commit_boundary_suite_packet=$STAGE777_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage779_preview_component_api_state_store_not_published_host_surface_after_stage778"
  echo "stage778_preview_component_api_state_store_rollback_snapshot_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage778 preview component api state-store rollback snapshot suite: route_classification=preview_api_state_store_rollback_snapshot"
echo "cjgui stage778 preview component api state-store rollback snapshot suite: suite_packet_path=$SUITE_PACKET"
