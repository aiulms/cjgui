#!/usr/bin/env zsh
#
# Focused suite for stage841. It consumes stage840 and records the owner-local
# text value / selection / caret / composition model.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE841_TMPDIR:-/private/tmp/cjgui-stage841-stage844/stage841}"
SUITE_PACKET="$TMP_DIR/stage841-publishable-state-text-model-suite.packet"
STAGE840_SUITE_PACKET="${CJGUI_STAGE841_INPUT_PACKET:-${CJGUI_STAGE840_PUBLISHABLE_STATE_FOCUS_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage837-stage840/stage840/stage840-publishable-state-focus-runtime-manager-suite.packet}}"
STAGE840_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage840_publishable_state_focus_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_owner.sh"
OWNER_LOG="$TMP_DIR/stage841-publishable-state-text-model-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage841 publishable state text model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE840_SUITE_PACKET" ]] || ! grep -F "stage840_publishable_state_focus_runtime_manager_suite_passed=true" "$STAGE840_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE840_TMPDIR="$TMP_DIR/stage840" zsh "$STAGE840_SUITE_SCRIPT" >/dev/null
  STAGE840_SUITE_PACKET="$TMP_DIR/stage840/stage840-publishable-state-focus-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage840_publishable_state_focus_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage840_publishable_state_focus_runtime_manager_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage841_publishable_state_text_model_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage840_publishable_state_focus_runtime_manager_consumed=true" \
  "stage839_publishable_state_focus_demo_surface_consumed_transitively=true" \
  "stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true" \
  "shared_publishable_focus_runtime_manager_consumed=true" \
  "owner_local_text_value_model_materialized=true" \
  "text_run_ledger_materialized=true" \
  "selection_range_model_materialized=true" \
  "caret_position_model_materialized=true" \
  "composition_placeholder_model_materialized=true" \
  "text_model_bound_to_stage834_measurement_plan=true" \
  "text_model_bound_to_stage840_focus_runtime_manager=true" \
  "stage842_publishable_state_text_edit_preview_prepared=true" \
  "text_shaping_enabled=false" \
  "text_mutation=false" \
  "input_pipeline_execution=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage840_publishable_state_focus_runtime_manager_suite_passed=true" \
  "stage841_publishable_state_text_model_after_stage840_prepared=true" \
  "shared_publishable_focus_runtime_manager_materialized=true" \
  "focus_runtime_manager_bound_to_stage837_focus_manager_input=true"; do
  require_file_fact "$STAGE840_SUITE_PACKET" "$fact"
done

{
  echo "stage841_publishable_state_text_model_suite_version=1"
  echo "stage840_suite_packet=$STAGE840_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage842_publishable_state_text_edit_preview_after_stage841"
  echo "stage841_publishable_state_text_model_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage841 publishable state text model suite: route_classification=text_model"
echo "cjgui stage841 publishable state text model suite: suite_packet_path=$SUITE_PACKET"
