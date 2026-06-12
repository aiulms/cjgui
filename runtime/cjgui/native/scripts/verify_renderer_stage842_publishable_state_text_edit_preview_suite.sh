#!/usr/bin/env zsh
#
# Focused suite for stage842. It consumes stage841 and records non-dispatching
# text edit / selection-caret / composition / rollback preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE842_TMPDIR:-/private/tmp/cjgui-stage841-stage844/stage842}"
SUITE_PACKET="$TMP_DIR/stage842-publishable-state-text-edit-preview-suite.packet"
STAGE841_SUITE_PACKET="${CJGUI_STAGE842_INPUT_PACKET:-${CJGUI_STAGE841_PUBLISHABLE_STATE_TEXT_MODEL_SUITE_PACKET:-/private/tmp/cjgui-stage841-stage844/stage841/stage841-publishable-state-text-model-suite.packet}}"
STAGE841_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage842-publishable-state-text-edit-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage842 publishable state text edit preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE841_SUITE_PACKET" ]] || ! grep -F "stage841_publishable_state_text_model_suite_passed=true" "$STAGE841_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE841_TMPDIR="$TMP_DIR/stage841" zsh "$STAGE841_SUITE_SCRIPT" >/dev/null
  STAGE841_SUITE_PACKET="$TMP_DIR/stage841/stage841-publishable-state-text-model-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage841_publishable_state_text_model_consumed=true" \
  "stage840_publishable_state_focus_runtime_manager_consumed_transitively=true" \
  "owner_local_text_value_model_consumed=true" \
  "owner_local_text_edit_preview_materialized=true" \
  "selection_caret_delta_preview_materialized=true" \
  "composition_placeholder_edit_preview_materialized=true" \
  "text_rollback_snapshot_materialized=true" \
  "text_change_explain_receipt_materialized=true" \
  "text_edit_preview_bound_to_stage841_text_model=true" \
  "stage843_publishable_state_text_demo_surface_prepared=true" \
  "text_mutation=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage841_publishable_state_text_model_suite_passed=true" \
  "owner_local_text_value_model_materialized=true" \
  "composition_placeholder_model_materialized=true" \
  "stage842_publishable_state_text_edit_preview_prepared=true"; do
  require_file_fact "$STAGE841_SUITE_PACKET" "$fact"
done

{
  echo "stage842_publishable_state_text_edit_preview_suite_version=1"
  echo "stage841_suite_packet=$STAGE841_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage843_publishable_state_text_demo_surface_after_stage842"
  echo "stage842_publishable_state_text_edit_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage842 publishable state text edit preview suite: route_classification=text_edit_preview"
echo "cjgui stage842 publishable state text edit preview suite: suite_packet_path=$SUITE_PACKET"
