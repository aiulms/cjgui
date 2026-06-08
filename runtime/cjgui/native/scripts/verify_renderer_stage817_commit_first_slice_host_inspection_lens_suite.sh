#!/usr/bin/env zsh
#
# Focused suite for stage817. It consumes stage816 and records the shared
# commit first-slice host inspection lens.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE817_TMPDIR:-/private/tmp/cjgui-stage817-stage820/stage817}"
SUITE_PACKET="$TMP_DIR/stage817-commit-first-slice-host-inspection-lens-suite.packet"
STAGE816_SUITE_PACKET="${CJGUI_STAGE817_INPUT_PACKET:-${CJGUI_STAGE816_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_FIRST_SLICE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage813-stage816-postfmt/stage816/stage816-preview-component-api-state-store-commit-first-slice-runtime-manager-suite.packet}}"
STAGE816_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage817_commit_first_slice_host_inspection_lens_owner.sh"
OWNER_LOG="$TMP_DIR/stage817-commit-first-slice-host-inspection-lens-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage817 commit first-slice host inspection lens suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE816_SUITE_PACKET" ]] || ! grep -F "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_suite_passed=true" "$STAGE816_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE816_TMPDIR="$TMP_DIR/stage816" zsh "$STAGE816_SUITE_SCRIPT" >/dev/null
  STAGE816_SUITE_PACKET="$TMP_DIR/stage816/stage816-preview-component-api-state-store-commit-first-slice-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_consumed=true" \
  "commit_first_slice_write_set_inspection_rows_materialized=true" \
  "commit_first_slice_rollback_snapshot_inspection_rows_materialized=true" \
  "commit_first_slice_denial_ledger_inspection_rows_materialized=true" \
  "commit_first_slice_not_published_boundary_inspection_rows_materialized=true" \
  "commit_first_slice_component_slot_diff_inspection_rows_materialized=true" \
  "commit_first_slice_host_inspection_lens_bound_to_stage816_runtime_manager=true" \
  "stage818_commit_first_slice_inspection_filter_controller_prepared=true" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage816_preview_component_api_state_store_commit_first_slice_runtime_manager_suite_passed=true" \
  "shared_commit_first_slice_runtime_manager_materialized=true" \
  "file_browser_commit_first_slice_runtime_surface_materialized=true"; do
  require_file_fact "$STAGE816_SUITE_PACKET" "$fact"
done

{
  echo "stage817_commit_first_slice_host_inspection_lens_suite_version=1"
  echo "stage816_suite_packet=$STAGE816_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage817_commit_first_slice_host_inspection_lens_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage817 commit first-slice host inspection lens suite: route_classification=commit_host_inspection_lens"
echo "cjgui stage817 commit first-slice host inspection lens suite: suite_packet_path=$SUITE_PACKET"
