#!/usr/bin/env zsh
#
# Focused suite for stage815. It consumes stage814 and records checkable
# demo-host commit first-slice surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE815_TMPDIR:-/private/tmp/cjgui-stage813-stage816/stage815}"
SUITE_PACKET="$TMP_DIR/stage815-preview-component-api-state-store-commit-first-slice-demo-host-surface-suite.packet"
STAGE814_SUITE_PACKET="${CJGUI_STAGE815_INPUT_PACKET:-${CJGUI_STAGE814_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_FIRST_SLICE_DRY_RUN_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage813-stage816/stage814/stage814-preview-component-api-state-store-commit-first-slice-dry-run-executor-suite.packet}}"
STAGE814_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage815-preview-component-api-state-store-commit-first-slice-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage815 preview component api state-store commit first-slice demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE814_SUITE_PACKET" ]] || ! grep -F "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite_passed=true" "$STAGE814_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE814_TMPDIR="$TMP_DIR/stage814" zsh "$STAGE814_SUITE_SCRIPT" >/dev/null
  STAGE814_SUITE_PACKET="$TMP_DIR/stage814/stage814-preview-component-api-state-store-commit-first-slice-dry-run-executor-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_consumed=true" \
  "commit_inspection_rows_materialized=true" \
  "commit_result_surface_refresh_materialized=true" \
  "todo_commit_first_slice_preview_surface_materialized=true" \
  "settings_commit_first_slice_preview_surface_materialized=true" \
  "ai_generated_settings_commit_first_slice_preview_surface_materialized=true" \
  "chat_composer_commit_first_slice_preview_surface_materialized=true" \
  "file_browser_commit_first_slice_preview_surface_materialized=true" \
  "commit_demo_host_surface_bound_to_stage814_executor=true" \
  "commit_demo_host_surface_non_publishing=true" \
  "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_prepared=true" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite_passed=true" \
  "commit_dry_run_executor_materialized=true" \
  "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE814_SUITE_PACKET" "$fact"
done

{
  echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_suite_version=1"
  echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite_packet=$STAGE814_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage815 preview component api state-store commit first-slice demo-host surface suite: route_classification=state_store_commit_first_slice_demo_host_surface"
echo "cjgui stage815 preview component api state-store commit first-slice demo-host surface suite: suite_packet_path=$SUITE_PACKET"
