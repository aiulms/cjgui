#!/usr/bin/env zsh
#
# Focused suite for stage869. It consumes stage868 and records state-store public API readiness.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE869_TMPDIR:-/private/tmp/cjgui-stage869-stage872/stage869}"
SUITE_PACKET="$TMP_DIR/stage869-text-input-commit-state-store-public-api-readiness-suite.packet"
STAGE868_SUITE_PACKET="${CJGUI_STAGE869_INPUT_PACKET:-${CJGUI_STAGE868_TEXT_INPUT_COMMIT_PUBLIC_API_CONSUMPTION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage865-stage868/stage868/stage868-text-input-commit-public-api-consumption-runtime-manager-suite.packet}}"
STAGE868_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage868_text_input_commit_public_api_consumption_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage869_text_input_commit_state_store_public_api_readiness_owner.sh"
OWNER_LOG="$TMP_DIR/stage869-text-input-commit-state-store-public-api-readiness-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage869 text input commit state store public api readiness suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE868_SUITE_PACKET" ]] || ! grep -F "stage868_text_input_commit_public_api_consumption_runtime_manager_suite_passed=true" "$STAGE868_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE868_TMPDIR="$TMP_DIR/stage868" zsh "$STAGE868_SUITE_SCRIPT" >/dev/null
  STAGE868_SUITE_PACKET="$TMP_DIR/stage868/stage868-text-input-commit-public-api-consumption-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage868_text_input_commit_public_api_consumption_runtime_manager_suite_passed=true" \
  "text_input_commit_public_api_consumption_runtime_contract_materialized=true" \
  "stage869_text_input_commit_state_store_public_api_readiness_prepared=true"; do
  require_file_fact "$STAGE868_SUITE_PACKET" "$fact"
done

for fact in \
  "stage868_text_input_commit_public_api_consumption_runtime_manager_consumed=true" \
  "state_store_public_api_commit_readiness_contract_materialized=true" \
  "state_store_commit_candidate_ledger_materialized=true" \
  "rollback_not_published_boundary_carry_forward_materialized=true" \
  "owner_local_state_store_commit_first_slice_readiness_materialized=true" \
  "stage870_text_input_commit_state_store_public_api_admission_prepared=true" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage869_text_input_commit_state_store_public_api_readiness_suite_version=1"
  echo "stage868_suite_packet=$STAGE868_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage870_text_input_commit_state_store_public_api_admission_after_stage869"
  echo "stage869_text_input_commit_state_store_public_api_readiness_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage869 text input commit state store public api readiness suite: route_classification=state_store_public_api_readiness"
echo "cjgui stage869 text input commit state store public api readiness suite: suite_packet_path=$SUITE_PACKET"
