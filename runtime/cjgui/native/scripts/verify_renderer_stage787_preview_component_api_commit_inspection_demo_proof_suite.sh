#!/usr/bin/env zsh
#
# Focused suite for stage787. It consumes stage786 and records public-preview
# contract demo proof surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE787_TMPDIR:-/private/tmp/cjgui-stage785-stage788/stage787}"
SUITE_PACKET="$TMP_DIR/stage787-preview-component-api-commit-inspection-demo-proof-suite.packet"
STAGE786_SUITE_PACKET="${CJGUI_STAGE787_INPUT_PACKET:-${CJGUI_STAGE786_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_COMPATIBILITY_LEDGER_SUITE_PACKET:-/private/tmp/cjgui-stage785-stage788/stage786/stage786-preview-component-api-commit-inspection-compatibility-ledger-suite.packet}}"
STAGE786_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage786_preview_component_api_commit_inspection_compatibility_ledger_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage787_preview_component_api_commit_inspection_demo_proof_owner.sh"
OWNER_LOG="$TMP_DIR/stage787-preview-component-api-commit-inspection-demo-proof-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage787 preview component api commit inspection demo proof suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE786_SUITE_PACKET" ]] || ! grep -F "stage786_preview_component_api_commit_inspection_compatibility_ledger_suite_passed=true" "$STAGE786_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE786_TMPDIR="$TMP_DIR/stage786" zsh "$STAGE786_SUITE_SCRIPT" >/dev/null
  STAGE786_SUITE_PACKET="$TMP_DIR/stage786/stage786-preview-component-api-commit-inspection-compatibility-ledger-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage786_preview_component_api_commit_inspection_compatibility_ledger_consumed=true" \
  "todo_public_preview_contract_proof_surface_materialized=true" \
  "settings_public_preview_contract_proof_surface_materialized=true" \
  "ai_generated_settings_public_preview_contract_proof_surface_materialized=true" \
  "chat_composer_public_preview_contract_proof_surface_materialized=true" \
  "public_preview_contract_host_inspection_receipt_materialized=true" \
  "public_preview_contract_result_surface_refresh_materialized=true" \
  "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage786_preview_component_api_commit_inspection_compatibility_ledger_suite_passed=true" \
  "public_preview_compatibility_ledger_materialized=true" \
  "backward_compatibility_receipt_materialized=true" \
  "deprecation_rollback_note_materialized=true" \
  "stage787_preview_component_api_commit_inspection_demo_proof_prepared=true"; do
  require_file_fact "$STAGE786_SUITE_PACKET" "$fact"
done

{
  echo "stage787_preview_component_api_commit_inspection_demo_proof_suite_version=1"
  echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_suite_packet=$STAGE786_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage787_preview_component_api_commit_inspection_demo_proof_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage787 preview component api commit inspection demo proof suite: route_classification=public_preview_contract_demo_proof"
echo "cjgui stage787 preview component api commit inspection demo proof suite: suite_packet_path=$SUITE_PACKET"
