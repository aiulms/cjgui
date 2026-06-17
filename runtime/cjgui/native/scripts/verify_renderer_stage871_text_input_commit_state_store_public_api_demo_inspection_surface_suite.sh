#!/usr/bin/env zsh
#
# Focused suite for stage871. It consumes stage870 and records five demo inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE871_TMPDIR:-/private/tmp/cjgui-stage869-stage872/stage871}"
SUITE_PACKET="$TMP_DIR/stage871-text-input-commit-state-store-public-api-demo-inspection-surface-suite.packet"
STAGE870_SUITE_PACKET="${CJGUI_STAGE871_INPUT_PACKET:-${CJGUI_STAGE870_TEXT_INPUT_COMMIT_STATE_STORE_PUBLIC_API_ADMISSION_SUITE_PACKET:-/private/tmp/cjgui-stage869-stage872/stage870/stage870-text-input-commit-state-store-public-api-admission-suite.packet}}"
STAGE870_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage870_text_input_commit_state_store_public_api_admission_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage871_text_input_commit_state_store_public_api_demo_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage871-text-input-commit-state-store-public-api-demo-inspection-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage871 text input commit state store public api demo inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE870_SUITE_PACKET" ]] || ! grep -F "stage870_text_input_commit_state_store_public_api_admission_suite_passed=true" "$STAGE870_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE870_TMPDIR="$TMP_DIR/stage870" zsh "$STAGE870_SUITE_SCRIPT" >/dev/null
  STAGE870_SUITE_PACKET="$TMP_DIR/stage870/stage870-text-input-commit-state-store-public-api-admission-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage870_text_input_commit_state_store_public_api_admission_suite_passed=true" \
  "commit_candidate_admission_matrix_materialized=true" \
  "no_write_execution_receipt_materialized=true"; do
  require_file_fact "$STAGE870_SUITE_PACKET" "$fact"
done

for fact in \
  "stage870_text_input_commit_state_store_public_api_admission_consumed=true" \
  "todo_state_store_public_api_commit_inspection_surface_materialized=true" \
  "settings_state_store_public_api_commit_inspection_surface_materialized=true" \
  "ai_generated_settings_state_store_public_api_commit_inspection_surface_materialized=true" \
  "chat_composer_state_store_public_api_commit_inspection_surface_materialized=true" \
  "file_browser_state_store_public_api_commit_inspection_surface_materialized=true" \
  "rollback_no_write_result_rows_materialized=true" \
  "stage872_text_input_commit_state_store_public_api_runtime_manager_prepared=true" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_suite_version=1"
  echo "stage870_suite_packet=$STAGE870_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage872_text_input_commit_state_store_public_api_runtime_manager_after_stage871"
  echo "stage871_text_input_commit_state_store_public_api_demo_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage871 text input commit state store public api demo inspection surface suite: route_classification=state_store_public_api_demo_inspection_surface"
echo "cjgui stage871 text input commit state store public api demo inspection surface suite: suite_packet_path=$SUITE_PACKET"
