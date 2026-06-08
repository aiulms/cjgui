#!/usr/bin/env zsh
#
# Focused suite for stage814. It consumes stage813 and records the rollback-safe
# non-publishing commit dry-run executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE814_TMPDIR:-/private/tmp/cjgui-stage813-stage816/stage814}"
SUITE_PACKET="$TMP_DIR/stage814-preview-component-api-state-store-commit-first-slice-dry-run-executor-suite.packet"
STAGE813_SUITE_PACKET="${CJGUI_STAGE814_INPUT_PACKET:-${CJGUI_STAGE813_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_FIRST_SLICE_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage813-stage816/stage813/stage813-preview-component-api-state-store-commit-first-slice-preflight-suite.packet}}"
STAGE813_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage814-preview-component-api-state-store-commit-first-slice-dry-run-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage814 preview component api state-store commit first-slice dry-run executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE813_SUITE_PACKET" ]] || ! grep -F "stage813_preview_component_api_state_store_commit_first_slice_preflight_suite_passed=true" "$STAGE813_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE813_TMPDIR="$TMP_DIR/stage813" zsh "$STAGE813_SUITE_SCRIPT" >/dev/null
  STAGE813_SUITE_PACKET="$TMP_DIR/stage813/stage813-preview-component-api-state-store-commit-first-slice-preflight-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage813_preview_component_api_state_store_commit_first_slice_preflight_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage813_preview_component_api_state_store_commit_first_slice_preflight_consumed=true" \
  "commit_dry_run_executor_materialized=true" \
  "rollback_before_after_snapshot_materialized=true" \
  "commit_denial_reason_ledger_materialized=true" \
  "write_set_receipt_materialized=true" \
  "commit_first_slice_executor_bound_to_preflight_allowlist=true" \
  "commit_executor_non_publishing=true" \
  "stage815_preview_component_api_state_store_commit_first_slice_demo_host_surface_prepared=true" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage813_preview_component_api_state_store_commit_first_slice_preflight_suite_passed=true" \
  "commit_first_slice_slot_allowlist_materialized=true" \
  "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_prepared=true"; do
  require_file_fact "$STAGE813_SUITE_PACKET" "$fact"
done

{
  echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite_version=1"
  echo "stage813_preview_component_api_state_store_commit_first_slice_preflight_suite_packet=$STAGE813_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage814_preview_component_api_state_store_commit_first_slice_dry_run_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage814 preview component api state-store commit first-slice dry-run executor suite: route_classification=state_store_commit_first_slice_dry_run_executor"
echo "cjgui stage814 preview component api state-store commit first-slice dry-run executor suite: suite_packet_path=$SUITE_PACKET"
