#!/usr/bin/env zsh
#
# Focused suite for stage846. It consumes stage845 and records composition /
# selection / caret previews.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE846_TMPDIR:-/private/tmp/cjgui-stage845-stage848/stage846}"
SUITE_PACKET="$TMP_DIR/stage846-publishable-state-text-input-composition-preview-suite.packet"
STAGE845_SUITE_PACKET="${CJGUI_STAGE846_INPUT_PACKET:-${CJGUI_STAGE845_PUBLISHABLE_STATE_TEXT_INPUT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage845-stage848/stage845/stage845-publishable-state-text-input-adapter-suite.packet}}"
STAGE845_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage846-publishable-state-text-input-composition-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage846 publishable state text input composition preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE845_SUITE_PACKET" ]] || ! grep -F "stage845_publishable_state_text_input_adapter_suite_passed=true" "$STAGE845_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE845_TMPDIR="$TMP_DIR/stage845" zsh "$STAGE845_SUITE_SCRIPT" >/dev/null
  STAGE845_SUITE_PACKET="$TMP_DIR/stage845/stage845-publishable-state-text-input-adapter-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage846_publishable_state_text_input_composition_preview_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage845_publishable_state_text_input_adapter_consumed=true" \
  "normalized_text_input_intents_consumed=true" \
  "text_insertion_preview_materialized=true" \
  "selection_replacement_preview_materialized=true" \
  "caret_movement_preview_materialized=true" \
  "composition_commit_cancel_preview_materialized=true" \
  "text_input_rollback_snapshot_materialized=true" \
  "text_input_explain_receipt_materialized=true" \
  "composition_preview_bound_to_stage842_edit_preview=true" \
  "stage847_publishable_state_text_input_demo_surface_prepared=true" \
  "input_pipeline_execution=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage845_publishable_state_text_input_adapter_suite_passed=true" \
  "normalized_keyboard_text_intent_adapter_materialized=true" \
  "composition_preedit_intent_adapter_materialized=true" \
  "stage846_publishable_state_text_input_composition_preview_prepared=true"; do
  require_file_fact "$STAGE845_SUITE_PACKET" "$fact"
done

{
  echo "stage846_publishable_state_text_input_composition_preview_suite_version=1"
  echo "stage845_suite_packet=$STAGE845_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage847_publishable_state_text_input_demo_surface_after_stage846"
  echo "stage846_publishable_state_text_input_composition_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage846 publishable state text input composition preview suite: route_classification=text_input_composition_preview"
echo "cjgui stage846 publishable state text input composition preview suite: suite_packet_path=$SUITE_PACKET"
