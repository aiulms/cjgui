#!/usr/bin/env zsh
#
# Focused suite for stage775. It consumes stage774 and records host inspection /
# result surface evidence for preview component API commit admission.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE775_TMPDIR:-/private/tmp/cjgui-stage773-stage776/stage775}"
SUITE_PACKET="$TMP_DIR/stage775-preview-component-api-commit-admission-host-inspection-surface-suite.packet"
STAGE774_SUITE_PACKET="${CJGUI_STAGE775_INPUT_PACKET:-${CJGUI_STAGE774_PREVIEW_COMPONENT_API_COMMIT_DENIAL_ROLLBACK_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage773-stage776/stage774/stage774-preview-component-api-commit-denial-rollback-receipt-suite.packet}}"
STAGE774_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage774_preview_component_api_commit_denial_rollback_receipt_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage775_preview_component_api_commit_admission_host_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage775-preview-component-api-commit-admission-host-inspection-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage775 preview component api commit admission host inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE774_SUITE_PACKET" ]] || ! grep -F "stage774_preview_component_api_commit_denial_rollback_receipt_suite_passed=true" "$STAGE774_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE774_TMPDIR="$TMP_DIR/stage774" zsh "$STAGE774_SUITE_SCRIPT" >/dev/null
  STAGE774_SUITE_PACKET="$TMP_DIR/stage774/stage774-preview-component-api-commit-denial-rollback-receipt-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage774_preview_component_api_commit_denial_rollback_receipt_consumed=true" \
  "preview_component_api_commit_admission_host_inspection_rows_materialized=true" \
  "preview_component_api_commit_admission_result_surface_refresh_materialized=true" \
  "preview_component_api_commit_rollback_snapshot_preview_materialized=true" \
  "preview_component_api_commit_admission_semantic_diff_receipt_materialized=true" \
  "preview_component_api_commit_admission_focus_handoff_rows_materialized=true" \
  "preview_component_api_commit_admission_render_command_refresh_preview_materialized=true" \
  "chat_composer_preview_component_api_commit_admission_host_inspection_surface_materialized=true" \
  "commit_admission_host_inspection_surface_bound_to_stage774_receipt=true" \
  "stage776_preview_component_api_commit_admission_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage774_preview_component_api_commit_denial_rollback_receipt_suite_passed=true" \
  "preview_component_api_commit_admission_receipt_ledger_materialized=true" \
  "commit_denial_rollback_receipt_bound_to_stage773_admission_dry_run=true"; do
  require_file_fact "$STAGE774_SUITE_PACKET" "$fact"
done

{
  echo "stage775_preview_component_api_commit_admission_host_inspection_surface_suite_version=1"
  echo "stage774_preview_component_api_commit_denial_rollback_receipt_suite_packet=$STAGE774_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage776_preview_component_api_commit_admission_runtime_manager_after_stage775"
  echo "stage775_preview_component_api_commit_admission_host_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage775 preview component api commit admission host inspection surface suite: route_classification=preview_api_commit_admission_host_inspection_surface"
echo "cjgui stage775 preview component api commit admission host inspection surface suite: suite_packet_path=$SUITE_PACKET"
