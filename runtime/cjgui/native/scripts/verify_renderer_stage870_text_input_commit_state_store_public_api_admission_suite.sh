#!/usr/bin/env zsh
#
# Focused suite for stage870. It consumes stage869 and records public API admission evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE870_TMPDIR:-/private/tmp/cjgui-stage869-stage872/stage870}"
SUITE_PACKET="$TMP_DIR/stage870-text-input-commit-state-store-public-api-admission-suite.packet"
STAGE869_SUITE_PACKET="${CJGUI_STAGE870_INPUT_PACKET:-${CJGUI_STAGE869_TEXT_INPUT_COMMIT_STATE_STORE_PUBLIC_API_READINESS_SUITE_PACKET:-/private/tmp/cjgui-stage869-stage872/stage869/stage869-text-input-commit-state-store-public-api-readiness-suite.packet}}"
STAGE869_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage869_text_input_commit_state_store_public_api_readiness_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage870_text_input_commit_state_store_public_api_admission_owner.sh"
OWNER_LOG="$TMP_DIR/stage870-text-input-commit-state-store-public-api-admission-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage870 text input commit state store public api admission suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE869_SUITE_PACKET" ]] || ! grep -F "stage869_text_input_commit_state_store_public_api_readiness_suite_passed=true" "$STAGE869_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE869_TMPDIR="$TMP_DIR/stage869" zsh "$STAGE869_SUITE_SCRIPT" >/dev/null
  STAGE869_SUITE_PACKET="$TMP_DIR/stage869/stage869-text-input-commit-state-store-public-api-readiness-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage869_text_input_commit_state_store_public_api_readiness_suite_passed=true" \
  "state_store_commit_candidate_ledger_materialized=true" \
  "owner_local_state_store_commit_first_slice_readiness_materialized=true"; do
  require_file_fact "$STAGE869_SUITE_PACKET" "$fact"
done

for fact in \
  "stage869_text_input_commit_state_store_public_api_readiness_consumed=true" \
  "owner_local_state_store_public_api_admission_plan_materialized=true" \
  "commit_candidate_admission_matrix_materialized=true" \
  "not_published_admission_receipt_materialized=true" \
  "no_write_execution_receipt_materialized=true" \
  "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_prepared=true" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage870_text_input_commit_state_store_public_api_admission_suite_version=1"
  echo "stage869_suite_packet=$STAGE869_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage871_text_input_commit_state_store_public_api_demo_inspection_surface_after_stage870"
  echo "stage870_text_input_commit_state_store_public_api_admission_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage870 text input commit state store public api admission suite: route_classification=state_store_public_api_admission"
echo "cjgui stage870 text input commit state store public api admission suite: suite_packet_path=$SUITE_PACKET"
