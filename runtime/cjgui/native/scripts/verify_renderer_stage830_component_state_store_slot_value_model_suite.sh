#!/usr/bin/env zsh
#
# Focused suite for stage830. It consumes stage829 and records reusable slot
# values for text, selection, focus, style, and layout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE830_TMPDIR:-/private/tmp/cjgui-stage829-stage832/stage830}"
SUITE_PACKET="$TMP_DIR/stage830-component-state-store-slot-value-model-suite.packet"
STAGE829_SUITE_PACKET="${CJGUI_STAGE830_INPUT_PACKET:-${CJGUI_STAGE829_COMPONENT_STATE_STORE_PUBLISHABLE_STATE_MODEL_SUITE_PACKET:-/private/tmp/cjgui-stage829-stage832/stage829/stage829-component-state-store-publishable-state-model-suite.packet}}"
STAGE829_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_owner.sh"
OWNER_LOG="$TMP_DIR/stage830-component-state-store-slot-value-model-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage830 component state-store slot value model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE829_SUITE_PACKET" ]] || ! grep -F "stage829_component_state_store_publishable_state_model_suite_passed=true" "$STAGE829_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE829_TMPDIR="$TMP_DIR/stage829" zsh "$STAGE829_SUITE_SCRIPT" >/dev/null
  STAGE829_SUITE_PACKET="$TMP_DIR/stage829/stage829-component-state-store-publishable-state-model-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage829_component_state_store_publishable_state_model_consumed=true" \
  "stage828_commit_first_slice_publication_runtime_manager_consumed_transitively=true" \
  "component_slot_value_model_materialized=true" \
  "text_slot_value_materialized=true" \
  "selection_slot_value_materialized=true" \
  "focus_slot_value_materialized=true" \
  "style_slot_value_materialized=true" \
  "layout_slot_value_materialized=true" \
  "slot_value_coercion_ledger_materialized=true" \
  "slot_values_bound_to_stage829_publishable_state_model=true" \
  "stage831_component_state_store_commit_candidate_rollback_snapshot_prepared=true" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage829_component_state_store_publishable_state_model_suite_passed=true" \
  "owner_local_publishable_state_model_materialized=true" \
  "stage830_component_state_store_slot_value_model_prepared=true"; do
  require_file_fact "$STAGE829_SUITE_PACKET" "$fact"
done

{
  echo "stage830_component_state_store_slot_value_model_suite_version=1"
  echo "stage829_suite_packet=$STAGE829_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage831_component_state_store_commit_candidate_rollback_snapshot_after_stage830"
  echo "stage830_component_state_store_slot_value_model_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage830 component state-store slot value model suite: route_classification=slot_value_model"
echo "cjgui stage830 component state-store slot value model suite: suite_packet_path=$SUITE_PACKET"
