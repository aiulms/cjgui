#!/usr/bin/env zsh
#
# Focused suite for stage843. It consumes stage842 and records five demo-host
# text inspection/result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE843_TMPDIR:-/private/tmp/cjgui-stage841-stage844/stage843}"
SUITE_PACKET="$TMP_DIR/stage843-publishable-state-text-demo-surface-suite.packet"
STAGE842_SUITE_PACKET="${CJGUI_STAGE843_INPUT_PACKET:-${CJGUI_STAGE842_PUBLISHABLE_STATE_TEXT_EDIT_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage841-stage844/stage842/stage842-publishable-state-text-edit-preview-suite.packet}}"
STAGE842_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage843-publishable-state-text-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage843 publishable state text demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE842_SUITE_PACKET" ]] || ! grep -F "stage842_publishable_state_text_edit_preview_suite_passed=true" "$STAGE842_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE842_TMPDIR="$TMP_DIR/stage842" zsh "$STAGE842_SUITE_SCRIPT" >/dev/null
  STAGE842_SUITE_PACKET="$TMP_DIR/stage842/stage842-publishable-state-text-edit-preview-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage842_publishable_state_text_edit_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage843_publishable_state_text_demo_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage842_publishable_state_text_edit_preview_consumed=true" \
  "stage841_publishable_state_text_model_consumed_transitively=true" \
  "todo_text_inspection_surface_materialized=true" \
  "settings_text_inspection_surface_materialized=true" \
  "ai_generated_settings_text_inspection_surface_materialized=true" \
  "chat_composer_text_inspection_surface_materialized=true" \
  "file_browser_text_inspection_surface_materialized=true" \
  "text_result_surface_receipt_materialized=true" \
  "text_surface_bound_to_stage842_text_edit_preview=true" \
  "stage844_publishable_state_text_runtime_manager_prepared=true" \
  "host_mutation=false" \
  "text_dispatch=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage842_publishable_state_text_edit_preview_suite_passed=true" \
  "owner_local_text_edit_preview_materialized=true" \
  "text_change_explain_receipt_materialized=true" \
  "stage843_publishable_state_text_demo_surface_prepared=true"; do
  require_file_fact "$STAGE842_SUITE_PACKET" "$fact"
done

{
  echo "stage843_publishable_state_text_demo_surface_suite_version=1"
  echo "stage842_suite_packet=$STAGE842_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage844_publishable_state_text_runtime_manager_after_stage843"
  echo "stage843_publishable_state_text_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage843 publishable state text demo surface suite: route_classification=text_demo_surface"
echo "cjgui stage843 publishable state text demo surface suite: suite_packet_path=$SUITE_PACKET"
