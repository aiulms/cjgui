#!/usr/bin/env zsh
#
# Focused suite for stage835. It consumes stage834 and records five demo
# layout/style preview surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE835_TMPDIR:-/private/tmp/cjgui-stage833-stage836/stage835}"
SUITE_PACKET="$TMP_DIR/stage835-publishable-state-layout-style-demo-surface-suite.packet"
STAGE834_SUITE_PACKET="${CJGUI_STAGE835_INPUT_PACKET:-${CJGUI_STAGE834_PUBLISHABLE_STATE_TEXT_FOCUS_MEASUREMENT_PLAN_SUITE_PACKET:-/private/tmp/cjgui-stage833-stage836/stage834/stage834-publishable-state-text-focus-measurement-plan-suite.packet}}"
STAGE834_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage835-publishable-state-layout-style-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage835 publishable state layout style demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE834_SUITE_PACKET" ]] || ! grep -F "stage834_publishable_state_text_focus_measurement_plan_suite_passed=true" "$STAGE834_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE834_TMPDIR="$TMP_DIR/stage834" zsh "$STAGE834_SUITE_SCRIPT" >/dev/null
  STAGE834_SUITE_PACKET="$TMP_DIR/stage834/stage834-publishable-state-text-focus-measurement-plan-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage835_publishable_state_layout_style_demo_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage834_publishable_state_text_focus_measurement_plan_consumed=true" \
  "stage833_publishable_state_layout_style_resolver_consumed_transitively=true" \
  "todo_layout_style_preview_surface_materialized=true" \
  "settings_layout_style_preview_surface_materialized=true" \
  "ai_generated_settings_layout_style_preview_surface_materialized=true" \
  "chat_composer_layout_style_preview_surface_materialized=true" \
  "file_browser_layout_style_preview_surface_materialized=true" \
  "layout_style_result_surface_receipt_materialized=true" \
  "demo_surface_bound_to_text_focus_measurement_plan=true" \
  "stage836_publishable_state_layout_style_runtime_manager_prepared=true" \
  "host_mutation=false" \
  "layout_engine_enabled=false" \
  "style_resolver_production_enabled=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage834_publishable_state_text_focus_measurement_plan_suite_passed=true" \
  "text_run_measurement_input_materialized=true" \
  "focus_traversal_measurement_ledger_materialized=true" \
  "stage835_publishable_state_layout_style_demo_surface_prepared=true"; do
  require_file_fact "$STAGE834_SUITE_PACKET" "$fact"
done

{
  echo "stage835_publishable_state_layout_style_demo_surface_suite_version=1"
  echo "stage834_suite_packet=$STAGE834_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage836_publishable_state_layout_style_runtime_manager_after_stage835"
  echo "stage835_publishable_state_layout_style_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage835 publishable state layout style demo surface suite: route_classification=layout_style_demo_surface"
echo "cjgui stage835 publishable state layout style demo surface suite: suite_packet_path=$SUITE_PACKET"
