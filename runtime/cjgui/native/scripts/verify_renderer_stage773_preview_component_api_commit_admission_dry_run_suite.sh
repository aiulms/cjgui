#!/usr/bin/env zsh
#
# Focused suite for stage773. It consumes stage772 and records commit admission
# dry-run evidence without committing preview component API state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE773_TMPDIR:-/private/tmp/cjgui-stage773-stage776/stage773}"
SUITE_PACKET="$TMP_DIR/stage773-preview-component-api-commit-admission-dry-run-suite.packet"
STAGE772_SUITE_PACKET="${CJGUI_STAGE773_INPUT_PACKET:-${CJGUI_STAGE772_PREVIEW_COMPONENT_API_OWNER_ACCEPTANCE_DECISION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage769-stage772-run2/stage772/stage772-preview-component-api-owner-acceptance-decision-runtime-manager-suite.packet}}"
STAGE772_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage773_preview_component_api_commit_admission_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage773-preview-component-api-commit-admission-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage773 preview component api commit admission dry run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE772_SUITE_PACKET" ]] || ! grep -F "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite_passed=true" "$STAGE772_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE772_TMPDIR="$TMP_DIR/stage772" zsh "$STAGE772_SUITE_SCRIPT" >/dev/null
  STAGE772_SUITE_PACKET="$TMP_DIR/stage772/stage772-preview-component-api-owner-acceptance-decision-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_consumed=true" \
  "preview_component_api_commit_admission_dry_run_materialized=true" \
  "preview_component_api_accepted_commit_admission_candidate_materialized=true" \
  "preview_component_api_rejected_commit_admission_candidate_materialized=true" \
  "owner_decision_to_commit_admission_bridge_materialized=true" \
  "chat_composer_preview_component_api_commit_admission_surface_materialized=true" \
  "commit_admission_dry_run_bound_to_stage772_decision_runtime_manager=true" \
  "preview_component_api_commit_admission_non_committing=true" \
  "stage774_preview_component_api_commit_denial_rollback_receipt_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite_passed=true" \
  "shared_preview_component_api_owner_acceptance_decision_runtime_manager_materialized=true" \
  "stage773_preview_component_api_commit_admission_dry_run_prepared=true"; do
  require_file_fact "$STAGE772_SUITE_PACKET" "$fact"
done

{
  echo "stage773_preview_component_api_commit_admission_dry_run_suite_version=1"
  echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_suite_packet=$STAGE772_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage774_preview_component_api_commit_denial_rollback_receipt_after_stage773"
  echo "stage773_preview_component_api_commit_admission_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage773 preview component api commit admission dry run suite: route_classification=preview_api_commit_admission_dry_run"
echo "cjgui stage773 preview component api commit admission dry run suite: suite_packet_path=$SUITE_PACKET"
