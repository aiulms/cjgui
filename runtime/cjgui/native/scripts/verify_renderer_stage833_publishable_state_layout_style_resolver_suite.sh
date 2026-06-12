#!/usr/bin/env zsh
#
# Focused suite for stage833. It consumes stage832 and records layout/style
# resolver inputs derived from publishable state slots.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE833_TMPDIR:-/private/tmp/cjgui-stage833-stage836/stage833}"
SUITE_PACKET="$TMP_DIR/stage833-publishable-state-layout-style-resolver-suite.packet"
STAGE832_SUITE_PACKET="${CJGUI_STAGE833_INPUT_PACKET:-${CJGUI_STAGE832_COMPONENT_STATE_STORE_PUBLISHABLE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage829-stage832/stage832/stage832-component-state-store-publishable-runtime-manager-suite.packet}}"
STAGE832_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage832_component_state_store_publishable_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_owner.sh"
OWNER_LOG="$TMP_DIR/stage833-publishable-state-layout-style-resolver-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage833 publishable state layout style resolver suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE832_SUITE_PACKET" ]] || ! grep -F "stage832_component_state_store_publishable_runtime_manager_suite_passed=true" "$STAGE832_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE832_TMPDIR="$TMP_DIR/stage832" zsh "$STAGE832_SUITE_SCRIPT" >/dev/null
  STAGE832_SUITE_PACKET="$TMP_DIR/stage832/stage832-component-state-store-publishable-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage833_publishable_state_layout_style_resolver_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage832_component_state_store_publishable_runtime_manager_consumed=true" \
  "stage831_component_state_store_commit_candidate_rollback_snapshot_consumed_transitively=true" \
  "stage830_component_state_store_slot_value_model_consumed_transitively=true" \
  "publishable_state_layout_resolver_input_materialized=true" \
  "publishable_state_style_resolver_input_materialized=true" \
  "layout_slot_constraint_ledger_materialized=true" \
  "style_token_resolution_ledger_materialized=true" \
  "resolver_input_bound_to_stage830_slot_value_model=true" \
  "resolver_input_bound_to_stage832_runtime_manager=true" \
  "stage834_publishable_state_text_focus_measurement_plan_prepared=true" \
  "layout_engine_enabled=false" \
  "style_resolver_production_enabled=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage832_component_state_store_publishable_runtime_manager_suite_passed=true" \
  "publishable_state_runtime_contract_materialized=true" \
  "file_browser_publishable_state_runtime_surface_materialized=true" \
  "stage833_publishable_state_layout_style_resolver_after_stage832_prepared=true"; do
  require_file_fact "$STAGE832_SUITE_PACKET" "$fact"
done

{
  echo "stage833_publishable_state_layout_style_resolver_suite_version=1"
  echo "stage832_suite_packet=$STAGE832_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage834_publishable_state_text_focus_measurement_plan_after_stage833"
  echo "stage833_publishable_state_layout_style_resolver_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage833 publishable state layout style resolver suite: route_classification=layout_style_resolver_input"
echo "cjgui stage833 publishable state layout style resolver suite: suite_packet_path=$SUITE_PACKET"
