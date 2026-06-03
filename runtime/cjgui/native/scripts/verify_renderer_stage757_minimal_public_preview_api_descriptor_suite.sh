#!/usr/bin/env zsh
#
# Focused suite for stage757. It consumes stage756 and verifies the internal
# descriptor that will feed the minimal public preview API declaration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE757_TMPDIR:-/private/tmp/cjgui-stage757-stage760/stage757}"
SUITE_PACKET="$TMP_DIR/stage757-minimal-public-preview-api-descriptor-suite.packet"
STAGE756_SUITE_PACKET="${CJGUI_STAGE757_INPUT_PACKET:-${CJGUI_STAGE756_AI_GENERATED_UI_ACCEPTANCE_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage753-stage756/stage756/stage756-ai-generated-ui-acceptance-commit-runtime-manager-suite.packet}}"
STAGE756_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage757_minimal_public_preview_api_descriptor_owner.sh"
OWNER_LOG="$TMP_DIR/stage757-minimal-public-preview-api-descriptor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage757 minimal public preview api descriptor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE756_SUITE_PACKET" ]] || ! grep -F "stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite_passed=true" "$STAGE756_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE756_TMPDIR="$TMP_DIR/stage756" zsh "$STAGE756_SUITE_SCRIPT" >/dev/null
  STAGE756_SUITE_PACKET="$TMP_DIR/stage756/stage756-ai-generated-ui-acceptance-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage756_ai_generated_ui_acceptance_commit_runtime_manager_consumed=true" \
  "acceptance_commit_runtime_contract_consumed=true" \
  "minimal_public_preview_component_descriptor_materialized=true" \
  "preview_compatibility_ledger_materialized=true" \
  "preview_rollback_deprecation_note_materialized=true" \
  "preview_descriptor_bound_to_acceptance_commit_runtime_contract=true" \
  "preview_api_experimental=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "stage758_minimal_public_preview_api_declaration_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite_passed=true" \
  "acceptance_commit_runtime_contract_materialized=true" \
  "acceptance_commit_execution_receipt_contract_materialized=true" \
  "stage757_minimal_public_preview_api_first_slice_prepared=true" \
  "stable_public_api_added=false"; do
  require_file_fact "$STAGE756_SUITE_PACKET" "$fact"
done

{
  echo "stage757_minimal_public_preview_api_descriptor_suite_version=1"
  echo "stage756_ai_generated_ui_acceptance_commit_runtime_manager_suite_packet=$STAGE756_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage757_minimal_public_preview_api_descriptor_suite_passed=true"
  echo "next_route=stage758_minimal_public_preview_api_declaration_after_stage757"
} > "$SUITE_PACKET"

echo "cjgui stage757 minimal public preview api descriptor suite: route_classification=preview_api_descriptor_ready"
echo "cjgui stage757 minimal public preview api descriptor suite: suite_packet_path=$SUITE_PACKET"
