#!/usr/bin/env zsh
#
# Focused suite for stage781. It consumes stage780 and verifies the commit
# inspection UI row model without committing state-store writes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE781_TMPDIR:-/private/tmp/cjgui-stage781-stage784/stage781}"
SUITE_PACKET="$TMP_DIR/stage781-preview-component-api-commit-inspection-ui-suite.packet"
STAGE780_SUITE_PACKET="${CJGUI_STAGE781_INPUT_PACKET:-${CJGUI_STAGE780_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage777-stage780/stage780/stage780-preview-component-api-state-store-commit-runtime-manager-suite.packet}}"
STAGE780_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage780_preview_component_api_state_store_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage781_preview_component_api_commit_inspection_ui_owner.sh"
OWNER_LOG="$TMP_DIR/stage781-preview-component-api-commit-inspection-ui-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage781 preview component api commit inspection ui suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE780_SUITE_PACKET" ]] || ! grep -F "stage780_preview_component_api_state_store_commit_runtime_manager_suite_passed=true" "$STAGE780_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE780_TMPDIR="$TMP_DIR/stage780" zsh "$STAGE780_SUITE_SCRIPT" >/dev/null
  STAGE780_SUITE_PACKET="$TMP_DIR/stage780/stage780-preview-component-api-state-store-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage780_preview_component_api_state_store_commit_runtime_manager_consumed=true" \
  "commit_inspection_ui_row_model_materialized=true" \
  "commit_write_set_review_rows_materialized=true" \
  "commit_rollback_preview_rows_materialized=true" \
  "commit_not_published_status_banner_materialized=true" \
  "chat_composer_preview_component_api_commit_inspection_ui_surface_materialized=true" \
  "commit_inspection_ui_bound_to_stage780_runtime_manager=true" \
  "stage782_preview_component_api_commit_inspection_review_actions_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage780_preview_component_api_state_store_commit_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_state_store_commit_runtime_manager_materialized=true" \
  "stage781_preview_component_api_commit_inspection_ui_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE780_SUITE_PACKET" "$fact"
done

{
  echo "stage781_preview_component_api_commit_inspection_ui_suite_version=1"
  echo "stage780_preview_component_api_state_store_commit_runtime_manager_suite_packet=$STAGE780_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage782_preview_component_api_commit_inspection_review_actions_after_stage781"
  echo "stage781_preview_component_api_commit_inspection_ui_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage781 preview component api commit inspection ui suite: route_classification=preview_api_commit_inspection_ui"
echo "cjgui stage781 preview component api commit inspection ui suite: suite_packet_path=$SUITE_PACKET"
