#!/usr/bin/env zsh
#
# Focused suite for stage771. It consumes stage770 and records host-checkable
# accept/reject feedback surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE771_TMPDIR:-/private/tmp/cjgui-stage769-stage772/stage771}"
SUITE_PACKET="$TMP_DIR/stage771-preview-component-api-acceptance-feedback-surface-suite.packet"
STAGE770_SUITE_PACKET="${CJGUI_STAGE771_INPUT_PACKET:-${CJGUI_STAGE770_PREVIEW_COMPONENT_API_ACCEPTANCE_DECISION_REDUCER_SUITE_PACKET:-/private/tmp/cjgui-stage769-stage772/stage770/stage770-preview-component-api-acceptance-decision-reducer-suite.packet}}"
STAGE770_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage770_preview_component_api_acceptance_decision_reducer_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage771_preview_component_api_acceptance_feedback_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage771-preview-component-api-acceptance-feedback-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage771 preview component api acceptance feedback surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE770_SUITE_PACKET" ]] || ! grep -F "stage770_preview_component_api_acceptance_decision_reducer_suite_passed=true" "$STAGE770_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE770_TMPDIR="$TMP_DIR/stage770" zsh "$STAGE770_SUITE_SCRIPT" >/dev/null
  STAGE770_SUITE_PACKET="$TMP_DIR/stage770/stage770-preview-component-api-acceptance-decision-reducer-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage770_preview_component_api_acceptance_decision_reducer_consumed=true" \
  "preview_component_api_acceptance_feedback_rows_materialized=true" \
  "preview_component_api_reject_reason_feedback_rows_materialized=true" \
  "preview_component_api_semantic_diff_acknowledge_rows_materialized=true" \
  "preview_component_api_commit_result_surface_refresh_materialized=true" \
  "preview_component_api_focus_review_rows_materialized=true" \
  "chat_composer_preview_component_api_acceptance_feedback_surface_materialized=true" \
  "acceptance_feedback_surface_bound_to_stage770_decision_reducer=true" \
  "acceptance_feedback_surface_host_inspectable=true" \
  "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage770_preview_component_api_acceptance_decision_reducer_suite_passed=true" \
  "preview_component_api_decision_receipt_ledger_materialized=true" \
  "acceptance_decision_reducer_bound_to_stage769_boundary=true"; do
  require_file_fact "$STAGE770_SUITE_PACKET" "$fact"
done

{
  echo "stage771_preview_component_api_acceptance_feedback_surface_suite_version=1"
  echo "stage770_preview_component_api_acceptance_decision_reducer_suite_packet=$STAGE770_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage772_preview_component_api_owner_acceptance_decision_runtime_manager_after_stage771"
  echo "stage771_preview_component_api_acceptance_feedback_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage771 preview component api acceptance feedback surface suite: route_classification=preview_api_acceptance_feedback_surface"
echo "cjgui stage771 preview component api acceptance feedback surface suite: suite_packet_path=$SUITE_PACKET"
