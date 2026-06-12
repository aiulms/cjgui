#!/usr/bin/env zsh
#
# Focused suite for stage834. It consumes stage833 and records text/focus
# measurement placeholders for the resolver preview path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE834_TMPDIR:-/private/tmp/cjgui-stage833-stage836/stage834}"
SUITE_PACKET="$TMP_DIR/stage834-publishable-state-text-focus-measurement-plan-suite.packet"
STAGE833_SUITE_PACKET="${CJGUI_STAGE834_INPUT_PACKET:-${CJGUI_STAGE833_PUBLISHABLE_STATE_LAYOUT_STYLE_RESOLVER_SUITE_PACKET:-/private/tmp/cjgui-stage833-stage836/stage833/stage833-publishable-state-layout-style-resolver-suite.packet}}"
STAGE833_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_owner.sh"
OWNER_LOG="$TMP_DIR/stage834-publishable-state-text-focus-measurement-plan-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage834 publishable state text focus measurement plan suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE833_SUITE_PACKET" ]] || ! grep -F "stage833_publishable_state_layout_style_resolver_suite_passed=true" "$STAGE833_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE833_TMPDIR="$TMP_DIR/stage833" zsh "$STAGE833_SUITE_SCRIPT" >/dev/null
  STAGE833_SUITE_PACKET="$TMP_DIR/stage833/stage833-publishable-state-layout-style-resolver-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage834_publishable_state_text_focus_measurement_plan_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage833_publishable_state_layout_style_resolver_consumed=true" \
  "stage832_component_state_store_publishable_runtime_manager_consumed_transitively=true" \
  "layout_style_resolver_input_consumed=true" \
  "text_run_measurement_input_materialized=true" \
  "selection_range_measurement_input_materialized=true" \
  "caret_geometry_placeholder_materialized=true" \
  "focus_traversal_measurement_ledger_materialized=true" \
  "measurement_plan_bound_to_layout_style_resolver=true" \
  "stage835_publishable_state_layout_style_demo_surface_prepared=true" \
  "text_shaping_enabled=false" \
  "focus_manager_enabled=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage833_publishable_state_layout_style_resolver_suite_passed=true" \
  "publishable_state_layout_resolver_input_materialized=true" \
  "style_token_resolution_ledger_materialized=true" \
  "stage834_publishable_state_text_focus_measurement_plan_prepared=true"; do
  require_file_fact "$STAGE833_SUITE_PACKET" "$fact"
done

{
  echo "stage834_publishable_state_text_focus_measurement_plan_suite_version=1"
  echo "stage833_suite_packet=$STAGE833_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage835_publishable_state_layout_style_demo_surface_after_stage834"
  echo "stage834_publishable_state_text_focus_measurement_plan_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage834 publishable state text focus measurement plan suite: route_classification=text_focus_measurement_plan"
echo "cjgui stage834 publishable state text focus measurement plan suite: suite_packet_path=$SUITE_PACKET"
