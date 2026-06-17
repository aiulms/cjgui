#!/usr/bin/env zsh
#
# Focused suite for stage863. It consumes stage862 and records demo-host
# acceptance inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE863_TMPDIR:-/private/tmp/cjgui-stage861-stage864/stage863}"
SUITE_PACKET="$TMP_DIR/stage863-text-input-acceptance-demo-host-surface-suite.packet"
STAGE862_SUITE_PACKET="${CJGUI_STAGE863_INPUT_PACKET:-${CJGUI_STAGE862_TEXT_INPUT_ACCEPTANCE_DECISION_REDUCER_SUITE_PACKET:-/private/tmp/cjgui-stage861-stage864/stage862/stage862-text-input-acceptance-decision-reducer-suite.packet}}"
STAGE862_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage862_text_input_acceptance_decision_reducer_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage863_text_input_acceptance_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage863-text-input-acceptance-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage863 text input acceptance demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE862_SUITE_PACKET" ]] || ! grep -F "stage862_text_input_acceptance_decision_reducer_suite_passed=true" "$STAGE862_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE862_TMPDIR="$TMP_DIR/stage862" zsh "$STAGE862_SUITE_SCRIPT" >/dev/null
  STAGE862_SUITE_PACKET="$TMP_DIR/stage862/stage862-text-input-acceptance-decision-reducer-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage862_text_input_acceptance_decision_reducer_consumed=true" \
  "stage861_text_input_owner_acceptance_review_gate_consumed_transitively=true" \
  "todo_text_input_acceptance_surface_materialized=true" \
  "settings_text_input_acceptance_surface_materialized=true" \
  "ai_generated_settings_text_input_acceptance_surface_materialized=true" \
  "chat_composer_text_input_acceptance_surface_materialized=true" \
  "file_browser_text_input_acceptance_surface_materialized=true" \
  "text_input_acceptance_inspection_rows_materialized=true" \
  "text_input_acceptance_not_published_boundary_banner_materialized=true" \
  "stage864_text_input_owner_acceptance_runtime_manager_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

require_file_fact "$STAGE862_SUITE_PACKET" "stage862_text_input_acceptance_decision_reducer_suite_passed=true"
require_file_fact "$STAGE862_SUITE_PACKET" "owner_acceptance_not_published_receipt_materialized=true"

{
  echo "stage863_text_input_acceptance_demo_host_surface_suite_version=1"
  echo "stage862_suite_packet=$STAGE862_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage864_text_input_owner_acceptance_runtime_manager_after_stage863"
  echo "stage863_text_input_acceptance_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage863 text input acceptance demo-host surface suite: route_classification=acceptance_demo_host_surface"
echo "cjgui stage863 text input acceptance demo-host surface suite: suite_packet_path=$SUITE_PACKET"
