#!/usr/bin/env zsh
#
# Focused suite for stage867. It consumes stage866 and records the demo proof
# surfaces for public API consumption of the text-input commit evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE867_TMPDIR:-/private/tmp/cjgui-stage865-stage868/stage867}"
SUITE_PACKET="$TMP_DIR/stage867-text-input-commit-public-api-demo-proof-surface-suite.packet"
STAGE866_SUITE_PACKET="${CJGUI_STAGE867_INPUT_PACKET:-${CJGUI_STAGE866_TEXT_INPUT_COMMIT_PUBLIC_API_COMPATIBILITY_LEDGER_SUITE_PACKET:-/private/tmp/cjgui-stage865-stage868/stage866/stage866-text-input-commit-public-api-compatibility-ledger-suite.packet}}"
STAGE866_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage866_text_input_commit_public_api_compatibility_ledger_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage867_text_input_commit_public_api_demo_proof_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage867-text-input-commit-public-api-demo-proof-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage867 text input commit public api demo proof surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE866_SUITE_PACKET" ]] || ! grep -F "stage866_text_input_commit_public_api_compatibility_ledger_suite_passed=true" "$STAGE866_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE866_TMPDIR="$TMP_DIR/stage866" zsh "$STAGE866_SUITE_SCRIPT" >/dev/null
  STAGE866_SUITE_PACKET="$TMP_DIR/stage866/stage866-text-input-commit-public-api-compatibility-ledger-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage867_text_input_commit_public_api_demo_proof_surface_owner_present=true" \
  "stage866_text_input_commit_public_api_compatibility_ledger_consumed=true" \
  "todo_public_api_commit_proof_surface_materialized=true" \
  "settings_public_api_commit_proof_surface_materialized=true" \
  "ai_generated_settings_public_api_commit_proof_surface_materialized=true" \
  "chat_composer_public_api_commit_proof_surface_materialized=true" \
  "file_browser_public_api_commit_proof_surface_materialized=true" \
  "public_api_host_inspection_receipt_materialized=true" \
  "public_api_commit_result_surface_refresh_materialized=true" \
  "stage868_text_input_commit_public_api_consumption_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage866_text_input_commit_public_api_compatibility_ledger_suite_passed=true" \
  "public_api_compatibility_ledger_materialized=true" \
  "experimental_api_stability_boundary_materialized=true"; do
  require_file_fact "$STAGE866_SUITE_PACKET" "$fact"
done

{
  echo "stage867_text_input_commit_public_api_demo_proof_surface_suite_version=1"
  echo "stage866_suite_packet=$STAGE866_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage868_text_input_commit_public_api_consumption_runtime_manager_after_stage867"
  echo "stage867_text_input_commit_public_api_demo_proof_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage867 text input commit public api demo proof surface suite: route_classification=text_input_commit_public_api_demo_proof_surface"
echo "cjgui stage867 text input commit public api demo proof surface suite: suite_packet_path=$SUITE_PACKET"
