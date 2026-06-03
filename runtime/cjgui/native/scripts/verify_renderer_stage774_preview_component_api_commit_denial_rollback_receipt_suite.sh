#!/usr/bin/env zsh
#
# Focused suite for stage774. It consumes stage773 and records denial /
# rollback receipt evidence for preview component API commit admission.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE774_TMPDIR:-/private/tmp/cjgui-stage773-stage776/stage774}"
SUITE_PACKET="$TMP_DIR/stage774-preview-component-api-commit-denial-rollback-receipt-suite.packet"
STAGE773_SUITE_PACKET="${CJGUI_STAGE774_INPUT_PACKET:-${CJGUI_STAGE773_PREVIEW_COMPONENT_API_COMMIT_ADMISSION_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage773-stage776/stage773/stage773-preview-component-api-commit-admission-dry-run-suite.packet}}"
STAGE773_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage773_preview_component_api_commit_admission_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage774_preview_component_api_commit_denial_rollback_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage774-preview-component-api-commit-denial-rollback-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage774 preview component api commit denial rollback receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE773_SUITE_PACKET" ]] || ! grep -F "stage773_preview_component_api_commit_admission_dry_run_suite_passed=true" "$STAGE773_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE773_TMPDIR="$TMP_DIR/stage773" zsh "$STAGE773_SUITE_SCRIPT" >/dev/null
  STAGE773_SUITE_PACKET="$TMP_DIR/stage773/stage773-preview-component-api-commit-admission-dry-run-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage773_preview_component_api_commit_admission_dry_run_consumed=true" \
  "preview_component_api_commit_admission_denial_receipt_materialized=true" \
  "preview_component_api_commit_rollback_reason_receipt_materialized=true" \
  "preview_component_api_compatibility_denial_receipt_materialized=true" \
  "preview_component_api_owner_reject_denial_receipt_materialized=true" \
  "preview_component_api_commit_admission_receipt_ledger_materialized=true" \
  "chat_composer_preview_component_api_commit_denial_rollback_receipt_surface_materialized=true" \
  "commit_denial_rollback_receipt_bound_to_stage773_admission_dry_run=true" \
  "stage775_preview_component_api_commit_admission_host_inspection_surface_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage773_preview_component_api_commit_admission_dry_run_suite_passed=true" \
  "preview_component_api_commit_admission_dry_run_materialized=true" \
  "preview_component_api_commit_admission_non_committing=true"; do
  require_file_fact "$STAGE773_SUITE_PACKET" "$fact"
done

{
  echo "stage774_preview_component_api_commit_denial_rollback_receipt_suite_version=1"
  echo "stage773_preview_component_api_commit_admission_dry_run_suite_packet=$STAGE773_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage775_preview_component_api_commit_admission_host_inspection_surface_after_stage774"
  echo "stage774_preview_component_api_commit_denial_rollback_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage774 preview component api commit denial rollback receipt suite: route_classification=preview_api_commit_denial_rollback_receipt"
echo "cjgui stage774 preview component api commit denial rollback receipt suite: suite_packet_path=$SUITE_PACKET"
