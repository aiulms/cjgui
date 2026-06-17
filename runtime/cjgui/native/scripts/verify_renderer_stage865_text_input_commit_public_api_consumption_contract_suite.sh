#!/usr/bin/env zsh
#
# Focused suite for stage865. It consumes stage864 and records the
# text-input commit public API consumption contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE865_TMPDIR:-/private/tmp/cjgui-stage865-stage868/stage865}"
SUITE_PACKET="$TMP_DIR/stage865-text-input-commit-public-api-consumption-contract-suite.packet"
STAGE864_SUITE_PACKET="${CJGUI_STAGE865_INPUT_PACKET:-${CJGUI_STAGE864_TEXT_INPUT_OWNER_ACCEPTANCE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage861-stage864/stage864/stage864-text-input-owner-acceptance-runtime-manager-suite.packet}}"
STAGE864_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage865_text_input_commit_public_api_consumption_contract_owner.sh"
OWNER_LOG="$TMP_DIR/stage865-text-input-commit-public-api-consumption-contract-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage865 text input commit public api consumption contract suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE864_SUITE_PACKET" ]] || ! grep -F "stage864_text_input_owner_acceptance_runtime_manager_suite_passed=true" "$STAGE864_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE864_TMPDIR="$TMP_DIR/stage864" zsh "$STAGE864_SUITE_SCRIPT" >/dev/null
  STAGE864_SUITE_PACKET="$TMP_DIR/stage864/stage864-text-input-owner-acceptance-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage864_text_input_owner_acceptance_runtime_manager_consumed=true" \
  "existing_experimental_component_preview_api_readiness_consumed=true" \
  "text_input_commit_public_api_consumption_contract_materialized=true" \
  "owner_acceptance_receipt_public_api_projection_materialized=true" \
  "text_input_commit_candidate_public_api_projection_materialized=true" \
  "public_api_not_published_boundary_projection_materialized=true" \
  "public_api_consumption_contract_bound_to_stage864_runtime_manager=true" \
  "stage866_text_input_commit_public_api_compatibility_ledger_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage864_text_input_owner_acceptance_runtime_manager_suite_passed=true" \
  "shared_text_input_owner_acceptance_runtime_manager_materialized=true" \
  "stage865_text_input_commit_public_api_consumption_proof_prepared=true"; do
  require_file_fact "$STAGE864_SUITE_PACKET" "$fact"
done

{
  echo "stage865_text_input_commit_public_api_consumption_contract_suite_version=1"
  echo "stage864_suite_packet=$STAGE864_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage866_text_input_commit_public_api_compatibility_ledger_after_stage865"
  echo "stage865_text_input_commit_public_api_consumption_contract_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage865 text input commit public api consumption contract suite: route_classification=text_input_commit_public_api_consumption_contract"
echo "cjgui stage865 text input commit public api consumption contract suite: suite_packet_path=$SUITE_PACKET"
