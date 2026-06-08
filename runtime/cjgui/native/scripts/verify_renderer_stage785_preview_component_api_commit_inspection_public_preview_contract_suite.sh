#!/usr/bin/env zsh
#
# Focused suite for stage785. It consumes stage784 and records the public-preview
# contract descriptor for commit inspection evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE785_TMPDIR:-/private/tmp/cjgui-stage785-stage788/stage785}"
SUITE_PACKET="$TMP_DIR/stage785-preview-component-api-commit-inspection-public-preview-contract-suite.packet"
STAGE784_SUITE_PACKET="${CJGUI_STAGE785_INPUT_PACKET:-${CJGUI_STAGE784_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage781-stage784-closeout/stage784/stage784-preview-component-api-commit-inspection-runtime-manager-suite.packet}}"
STAGE784_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage784_preview_component_api_commit_inspection_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage785_preview_component_api_commit_inspection_public_preview_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage785-preview-component-api-commit-inspection-public-preview-contract-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage785 preview component api commit inspection public preview contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE784_SUITE_PACKET" ]] || ! grep -F "stage784_preview_component_api_commit_inspection_runtime_manager_suite_passed=true" "$STAGE784_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE784_TMPDIR="$TMP_DIR/stage784" zsh "$STAGE784_SUITE_SCRIPT" >/dev/null
  STAGE784_SUITE_PACKET="$TMP_DIR/stage784/stage784-preview-component-api-commit-inspection-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage784_preview_component_api_commit_inspection_runtime_manager_consumed=true" \
  "preview_component_api_commit_inspection_public_preview_descriptor_materialized=true" \
  "inspection_ui_review_result_public_preview_contract_materialized=true" \
  "existing_experimental_preview_api_surface_listed=true" \
  "public_preview_contract_bound_to_stage784_runtime_manager=true" \
  "stage786_preview_component_api_commit_inspection_compatibility_ledger_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage784_preview_component_api_commit_inspection_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_commit_inspection_runtime_manager_materialized=true" \
  "stage785_preview_component_api_commit_inspection_public_preview_contract_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE784_SUITE_PACKET" "$fact"
done

{
  echo "stage785_preview_component_api_commit_inspection_public_preview_contract_suite_version=1"
  echo "stage784_preview_component_api_commit_inspection_runtime_manager_suite_packet=$STAGE784_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage785_preview_component_api_commit_inspection_public_preview_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage785 preview component api commit inspection public preview contract suite: route_classification=public_preview_contract_descriptor"
echo "cjgui stage785 preview component api commit inspection public preview contract suite: suite_packet_path=$SUITE_PACKET"
