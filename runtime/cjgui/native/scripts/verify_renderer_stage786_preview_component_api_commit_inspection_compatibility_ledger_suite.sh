#!/usr/bin/env zsh
#
# Focused suite for stage786. It consumes stage785 and records the
# public-preview compatibility ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE786_TMPDIR:-/private/tmp/cjgui-stage785-stage788/stage786}"
SUITE_PACKET="$TMP_DIR/stage786-preview-component-api-commit-inspection-compatibility-ledger-suite.packet"
STAGE785_SUITE_PACKET="${CJGUI_STAGE786_INPUT_PACKET:-${CJGUI_STAGE785_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_PUBLIC_PREVIEW_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage785-stage788/stage785/stage785-preview-component-api-commit-inspection-public-preview-contract-suite.packet}}"
STAGE785_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage785_preview_component_api_commit_inspection_public_preview_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage786_preview_component_api_commit_inspection_compatibility_ledger_owner.sh"
OWNER_LOG="$TMP_DIR/stage786-preview-component-api-commit-inspection-compatibility-ledger-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage786 preview component api commit inspection compatibility ledger suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE785_SUITE_PACKET" ]] || ! grep -F "stage785_preview_component_api_commit_inspection_public_preview_contract_suite_passed=true" "$STAGE785_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE785_TMPDIR="$TMP_DIR/stage785" zsh "$STAGE785_SUITE_SCRIPT" >/dev/null
  STAGE785_SUITE_PACKET="$TMP_DIR/stage785/stage785-preview-component-api-commit-inspection-public-preview-contract-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage785_preview_component_api_commit_inspection_public_preview_contract_consumed=true" \
  "public_preview_compatibility_ledger_materialized=true" \
  "backward_compatibility_receipt_materialized=true" \
  "deprecation_rollback_note_materialized=true" \
  "commit_inspection_semantic_diff_explain_route_materialized=true" \
  "stage787_preview_component_api_commit_inspection_demo_proof_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage785_preview_component_api_commit_inspection_public_preview_contract_suite_passed=true" \
  "preview_component_api_commit_inspection_public_preview_descriptor_materialized=true" \
  "inspection_ui_review_result_public_preview_contract_materialized=true" \
  "stage786_preview_component_api_commit_inspection_compatibility_ledger_prepared=true"; do
  require_file_fact "$STAGE785_SUITE_PACKET" "$fact"
done

{
  echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_suite_version=1"
  echo "stage785_preview_component_api_commit_inspection_public_preview_contract_suite_packet=$STAGE785_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage786_preview_component_api_commit_inspection_compatibility_ledger_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage786 preview component api commit inspection compatibility ledger suite: route_classification=public_preview_compatibility_ledger"
echo "cjgui stage786 preview component api commit inspection compatibility ledger suite: suite_packet_path=$SUITE_PACKET"
