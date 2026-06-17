#!/usr/bin/env zsh
#
# Focused suite for stage866. It consumes stage865 and records the
# compatibility ledger for text-input commit public API consumption.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE866_TMPDIR:-/private/tmp/cjgui-stage865-stage868/stage866}"
SUITE_PACKET="$TMP_DIR/stage866-text-input-commit-public-api-compatibility-ledger-suite.packet"
STAGE865_SUITE_PACKET="${CJGUI_STAGE866_INPUT_PACKET:-${CJGUI_STAGE865_TEXT_INPUT_COMMIT_PUBLIC_API_CONSUMPTION_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage865-stage868/stage865/stage865-text-input-commit-public-api-consumption-contract-suite.packet}}"
STAGE865_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage865_text_input_commit_public_api_consumption_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage866_text_input_commit_public_api_compatibility_ledger_owner.sh"
OWNER_LOG="$TMP_DIR/stage866-text-input-commit-public-api-compatibility-ledger-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage866 text input commit public api compatibility ledger suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE865_SUITE_PACKET" ]] || ! grep -F "stage865_text_input_commit_public_api_consumption_contract_suite_passed=true" "$STAGE865_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE865_TMPDIR="$TMP_DIR/stage865" zsh "$STAGE865_SUITE_SCRIPT" >/dev/null
  STAGE865_SUITE_PACKET="$TMP_DIR/stage865/stage865-text-input-commit-public-api-consumption-contract-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage866_text_input_commit_public_api_compatibility_ledger_owner_present=true" \
  "stage865_text_input_commit_public_api_consumption_contract_consumed=true" \
  "public_api_compatibility_ledger_materialized=true" \
  "public_api_rollback_compatibility_note_materialized=true" \
  "public_api_not_published_compatibility_receipt_materialized=true" \
  "experimental_api_stability_boundary_materialized=true" \
  "stage867_text_input_commit_public_api_demo_proof_surface_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage865_text_input_commit_public_api_consumption_contract_suite_passed=true" \
  "text_input_commit_public_api_consumption_contract_materialized=true" \
  "new_public_surface_added=false"; do
  require_file_fact "$STAGE865_SUITE_PACKET" "$fact"
done

{
  echo "stage866_text_input_commit_public_api_compatibility_ledger_suite_version=1"
  echo "stage865_suite_packet=$STAGE865_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage867_text_input_commit_public_api_demo_proof_surface_after_stage866"
  echo "stage866_text_input_commit_public_api_compatibility_ledger_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage866 text input commit public api compatibility ledger suite: route_classification=text_input_commit_public_api_compatibility_ledger"
echo "cjgui stage866 text input commit public api compatibility ledger suite: suite_packet_path=$SUITE_PACKET"
