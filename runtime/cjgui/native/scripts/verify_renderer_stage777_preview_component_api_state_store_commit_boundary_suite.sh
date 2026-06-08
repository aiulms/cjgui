#!/usr/bin/env zsh
#
# Focused suite for stage777. It consumes stage776 and records preview
# component API state-store commit boundary evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE777_TMPDIR:-/private/tmp/cjgui-stage777-stage780/stage777}"
SUITE_PACKET="$TMP_DIR/stage777-preview-component-api-state-store-commit-boundary-suite.packet"
STAGE776_SUITE_PACKET="${CJGUI_STAGE777_INPUT_PACKET:-${CJGUI_STAGE776_PREVIEW_COMPONENT_API_COMMIT_ADMISSION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage773-stage776/stage776/stage776-preview-component-api-commit-admission-runtime-manager-suite.packet}}"
STAGE776_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage776_preview_component_api_commit_admission_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage777_preview_component_api_state_store_commit_boundary_owner.sh"
OWNER_LOG="$TMP_DIR/stage777-preview-component-api-state-store-commit-boundary-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage777 preview component api state-store commit boundary suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE776_SUITE_PACKET" ]] || ! grep -F "stage776_preview_component_api_commit_admission_runtime_manager_suite_passed=true" "$STAGE776_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE776_TMPDIR="$TMP_DIR/stage776" zsh "$STAGE776_SUITE_SCRIPT" >/dev/null
  STAGE776_SUITE_PACKET="$TMP_DIR/stage776/stage776-preview-component-api-commit-admission-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage776_preview_component_api_commit_admission_runtime_manager_consumed=true" \
  "preview_component_api_state_store_commit_boundary_materialized=true" \
  "owner_local_state_store_write_set_candidate_materialized=true" \
  "state_slot_admission_ledger_materialized=true" \
  "commit_admission_to_state_store_boundary_bridge_materialized=true" \
  "chat_composer_preview_component_api_state_store_commit_boundary_surface_materialized=true" \
  "state_store_commit_boundary_bound_to_stage776_runtime_manager=true" \
  "stage778_preview_component_api_state_store_rollback_snapshot_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage776_preview_component_api_commit_admission_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_commit_admission_runtime_manager_materialized=true" \
  "stage777_preview_component_api_state_store_commit_boundary_prepared=true"; do
  require_file_fact "$STAGE776_SUITE_PACKET" "$fact"
done

{
  echo "stage777_preview_component_api_state_store_commit_boundary_suite_version=1"
  echo "stage776_preview_component_api_commit_admission_runtime_manager_suite_packet=$STAGE776_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage778_preview_component_api_state_store_rollback_snapshot_after_stage777"
  echo "stage777_preview_component_api_state_store_commit_boundary_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage777 preview component api state-store commit boundary suite: route_classification=preview_api_state_store_commit_boundary"
echo "cjgui stage777 preview component api state-store commit boundary suite: suite_packet_path=$SUITE_PACKET"
