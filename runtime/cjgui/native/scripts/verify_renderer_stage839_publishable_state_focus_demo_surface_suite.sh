#!/usr/bin/env zsh
#
# Focused suite for stage839. It consumes stage838 and records five demo-host
# focus inspection/result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE839_TMPDIR:-/private/tmp/cjgui-stage837-stage840/stage839}"
SUITE_PACKET="$TMP_DIR/stage839-publishable-state-focus-demo-surface-suite.packet"
STAGE838_SUITE_PACKET="${CJGUI_STAGE839_INPUT_PACKET:-${CJGUI_STAGE838_PUBLISHABLE_STATE_FOCUS_MOVEMENT_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage837-stage840/stage838/stage838-publishable-state-focus-movement-preview-suite.packet}}"
STAGE838_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage839_publishable_state_focus_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage839-publishable-state-focus-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage839 publishable state focus demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE838_SUITE_PACKET" ]] || ! grep -F "stage838_publishable_state_focus_movement_preview_suite_passed=true" "$STAGE838_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE838_TMPDIR="$TMP_DIR/stage838" zsh "$STAGE838_SUITE_SCRIPT" >/dev/null
  STAGE838_SUITE_PACKET="$TMP_DIR/stage838/stage838-publishable-state-focus-movement-preview-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage837_publishable_state_focus_manager_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage838_publishable_state_focus_movement_preview_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage839_publishable_state_focus_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage839_publishable_state_focus_demo_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage838_publishable_state_focus_movement_preview_consumed=true" \
  "stage837_publishable_state_focus_manager_consumed_transitively=true" \
  "todo_focus_inspection_surface_materialized=true" \
  "settings_focus_inspection_surface_materialized=true" \
  "ai_generated_settings_focus_inspection_surface_materialized=true" \
  "chat_composer_focus_inspection_surface_materialized=true" \
  "file_browser_focus_inspection_surface_materialized=true" \
  "focus_result_surface_receipt_materialized=true" \
  "focus_surface_bound_to_stage838_movement_preview=true" \
  "stage840_publishable_state_focus_runtime_manager_prepared=true" \
  "host_mutation=false" \
  "focus_dispatch=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage838_publishable_state_focus_movement_preview_suite_passed=true" \
  "owner_local_focus_movement_preview_materialized=true" \
  "focus_change_explain_receipt_materialized=true" \
  "stage839_publishable_state_focus_demo_surface_prepared=true"; do
  require_file_fact "$STAGE838_SUITE_PACKET" "$fact"
done

{
  echo "stage839_publishable_state_focus_demo_surface_suite_version=1"
  echo "stage838_suite_packet=$STAGE838_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage840_publishable_state_focus_runtime_manager_after_stage839"
  echo "stage839_publishable_state_focus_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage839 publishable state focus demo surface suite: route_classification=focus_demo_surface"
echo "cjgui stage839 publishable state focus demo surface suite: suite_packet_path=$SUITE_PACKET"
