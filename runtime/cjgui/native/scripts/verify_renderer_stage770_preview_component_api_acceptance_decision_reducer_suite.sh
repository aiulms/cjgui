#!/usr/bin/env zsh
#
# Focused suite for stage770. It consumes stage769 and records the shared
# accept/reject decision reducer as a non-dispatching dry-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE770_TMPDIR:-/private/tmp/cjgui-stage769-stage772/stage770}"
SUITE_PACKET="$TMP_DIR/stage770-preview-component-api-acceptance-decision-reducer-suite.packet"
STAGE769_SUITE_PACKET="${CJGUI_STAGE770_INPUT_PACKET:-${CJGUI_STAGE769_PREVIEW_COMPONENT_API_OWNER_ACCEPTANCE_BOUNDARY_SUITE_PACKET:-/private/tmp/cjgui-stage769-stage772/stage769/stage769-preview-component-api-owner-acceptance-boundary-suite.packet}}"
STAGE769_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage769_preview_component_api_owner_acceptance_boundary_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage770_preview_component_api_acceptance_decision_reducer_owner.sh"
OWNER_LOG="$TMP_DIR/stage770-preview-component-api-acceptance-decision-reducer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage770 preview component api acceptance decision reducer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE769_SUITE_PACKET" ]] || ! grep -F "stage769_preview_component_api_owner_acceptance_boundary_suite_passed=true" "$STAGE769_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE769_TMPDIR="$TMP_DIR/stage769" zsh "$STAGE769_SUITE_SCRIPT" >/dev/null
  STAGE769_SUITE_PACKET="$TMP_DIR/stage769/stage769-preview-component-api-owner-acceptance-boundary-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage769_preview_component_api_owner_acceptance_boundary_consumed=true" \
  "preview_component_api_accept_decision_candidate_materialized=true" \
  "preview_component_api_reject_decision_candidate_materialized=true" \
  "preview_component_api_decision_conflict_classifier_materialized=true" \
  "preview_component_api_decision_rollback_plan_materialized=true" \
  "preview_component_api_decision_receipt_ledger_materialized=true" \
  "chat_composer_preview_component_api_acceptance_decision_surface_materialized=true" \
  "acceptance_decision_reducer_bound_to_stage769_boundary=true" \
  "acceptance_decision_reducer_non_dispatching=true" \
  "stage771_preview_component_api_acceptance_feedback_surface_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage769_preview_component_api_owner_acceptance_boundary_suite_passed=true" \
  "preview_component_api_owner_acceptance_boundary_materialized=true" \
  "owner_acceptance_boundary_bound_to_stage768_commit_runtime_manager=true"; do
  require_file_fact "$STAGE769_SUITE_PACKET" "$fact"
done

{
  echo "stage770_preview_component_api_acceptance_decision_reducer_suite_version=1"
  echo "stage769_preview_component_api_owner_acceptance_boundary_suite_packet=$STAGE769_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage771_preview_component_api_acceptance_feedback_surface_after_stage770"
  echo "stage770_preview_component_api_acceptance_decision_reducer_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage770 preview component api acceptance decision reducer suite: route_classification=preview_api_acceptance_decision_reducer"
echo "cjgui stage770 preview component api acceptance decision reducer suite: suite_packet_path=$SUITE_PACKET"
