#!/usr/bin/env zsh
#
# Focused suite for stage769. It consumes stage768 and records the owner
# acceptance boundary without admitting any commit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE769_TMPDIR:-/private/tmp/cjgui-stage769-stage772/stage769}"
SUITE_PACKET="$TMP_DIR/stage769-preview-component-api-owner-acceptance-boundary-suite.packet"
STAGE768_SUITE_PACKET="${CJGUI_STAGE769_INPUT_PACKET:-${CJGUI_STAGE768_PREVIEW_COMPONENT_API_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage769-stage772/stage768/stage768-preview-component-api-commit-runtime-manager-suite.packet}}"
STAGE768_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage768_preview_component_api_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage769_preview_component_api_owner_acceptance_boundary_owner.sh"
OWNER_LOG="$TMP_DIR/stage769-preview-component-api-owner-acceptance-boundary-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage769 preview component api owner acceptance boundary suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE768_SUITE_PACKET" ]] || ! grep -F "stage768_preview_component_api_commit_runtime_manager_suite_passed=true" "$STAGE768_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE768_TMPDIR="$TMP_DIR/stage768" zsh "$STAGE768_SUITE_SCRIPT" >/dev/null
  STAGE768_SUITE_PACKET="$TMP_DIR/stage768/stage768-preview-component-api-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage768_preview_component_api_commit_runtime_manager_consumed=true" \
  "preview_component_api_owner_acceptance_boundary_materialized=true" \
  "preview_component_api_owner_accept_token_requirement_materialized=true" \
  "preview_component_api_owner_reject_reason_requirement_materialized=true" \
  "preview_component_api_owner_review_checklist_materialized=true" \
  "chat_composer_preview_component_api_owner_acceptance_boundary_surface_materialized=true" \
  "owner_acceptance_boundary_bound_to_stage768_commit_runtime_manager=true" \
  "accept_reject_boundary_preview_only=true" \
  "stage770_preview_component_api_acceptance_decision_reducer_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage768_preview_component_api_commit_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_commit_runtime_manager_materialized=true" \
  "preview_component_api_commit_execution_receipt_contract_materialized=true"; do
  require_file_fact "$STAGE768_SUITE_PACKET" "$fact"
done

{
  echo "stage769_preview_component_api_owner_acceptance_boundary_suite_version=1"
  echo "stage768_preview_component_api_commit_runtime_manager_suite_packet=$STAGE768_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage770_preview_component_api_acceptance_decision_reducer_after_stage769"
  echo "stage769_preview_component_api_owner_acceptance_boundary_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage769 preview component api owner acceptance boundary suite: route_classification=preview_api_owner_acceptance_boundary"
echo "cjgui stage769 preview component api owner acceptance boundary suite: suite_packet_path=$SUITE_PACKET"
