#!/usr/bin/env zsh
#
# Focused suite for stage847. It consumes stage846 and records five demo-host
# text input preview/result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE847_TMPDIR:-/private/tmp/cjgui-stage845-stage848/stage847}"
SUITE_PACKET="$TMP_DIR/stage847-publishable-state-text-input-demo-surface-suite.packet"
STAGE846_SUITE_PACKET="${CJGUI_STAGE847_INPUT_PACKET:-${CJGUI_STAGE846_PUBLISHABLE_STATE_TEXT_INPUT_COMPOSITION_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage845-stage848/stage846/stage846-publishable-state-text-input-composition-preview-suite.packet}}"
STAGE846_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage847-publishable-state-text-input-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage847 publishable state text input demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE846_SUITE_PACKET" ]] || ! grep -F "stage846_publishable_state_text_input_composition_preview_suite_passed=true" "$STAGE846_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE846_TMPDIR="$TMP_DIR/stage846" zsh "$STAGE846_SUITE_SCRIPT" >/dev/null
  STAGE846_SUITE_PACKET="$TMP_DIR/stage846/stage846-publishable-state-text-input-composition-preview-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage847_publishable_state_text_input_demo_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage846_publishable_state_text_input_composition_preview_consumed=true" \
  "todo_text_input_preview_surface_materialized=true" \
  "settings_text_input_preview_surface_materialized=true" \
  "ai_generated_settings_text_input_preview_surface_materialized=true" \
  "chat_composer_text_input_preview_surface_materialized=true" \
  "file_browser_text_input_preview_surface_materialized=true" \
  "text_input_host_inspection_rows_materialized=true" \
  "input_feedback_clear_preview_materialized=true" \
  "text_input_result_surface_receipt_materialized=true" \
  "text_input_surface_bound_to_stage846_composition_preview=true" \
  "stage848_publishable_state_text_input_runtime_manager_prepared=true" \
  "host_mutation=false" \
  "text_dispatch=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage846_publishable_state_text_input_composition_preview_suite_passed=true" \
  "composition_commit_cancel_preview_materialized=true" \
  "text_input_explain_receipt_materialized=true" \
  "stage847_publishable_state_text_input_demo_surface_prepared=true"; do
  require_file_fact "$STAGE846_SUITE_PACKET" "$fact"
done

{
  echo "stage847_publishable_state_text_input_demo_surface_suite_version=1"
  echo "stage846_suite_packet=$STAGE846_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage848_publishable_state_text_input_runtime_manager_after_stage847"
  echo "stage847_publishable_state_text_input_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage847 publishable state text input demo surface suite: route_classification=text_input_demo_surface"
echo "cjgui stage847 publishable state text input demo surface suite: suite_packet_path=$SUITE_PACKET"
