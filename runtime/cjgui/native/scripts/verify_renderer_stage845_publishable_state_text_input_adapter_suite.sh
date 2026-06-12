#!/usr/bin/env zsh
#
# Focused suite for stage845. It consumes stage844 and checks the publishable
# state text input adapter bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE845_TMPDIR:-/private/tmp/cjgui-stage845-stage848/stage845}"
SUITE_PACKET="$TMP_DIR/stage845-publishable-state-text-input-adapter-suite.packet"
STAGE844_SUITE_PACKET="${CJGUI_STAGE845_INPUT_PACKET:-${CJGUI_STAGE844_PUBLISHABLE_STATE_TEXT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage841-stage844/stage844/stage844-publishable-state-text-runtime-manager-suite.packet}}"
STAGE844_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_suite.sh"
STAGE573_OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage573_component_runtime_text_input_demo_execution_contract_owner.sh"
STAGE573_OWNER_LOG="$TMP_DIR/stage573-component-runtime-text-input-demo-execution-contract-owner.log"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage845-publishable-state-text-input-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage845 publishable state text input adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE844_SUITE_PACKET" ]] || ! grep -F "stage844_publishable_state_text_runtime_manager_suite_passed=true" "$STAGE844_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE844_TMPDIR="$TMP_DIR/stage844" zsh "$STAGE844_SUITE_SCRIPT" >/dev/null
  STAGE844_SUITE_PACKET="$TMP_DIR/stage844/stage844-publishable-state-text-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage844_publishable_state_text_runtime_manager_suite.sh" \
  "$STAGE573_OWNER_SCRIPT" \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage845_publishable_state_text_input_adapter_suite.sh"; do
  zsh -n "$script"
done

zsh "$STAGE573_OWNER_SCRIPT" > "$STAGE573_OWNER_LOG" 2>&1
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage844_publishable_state_text_runtime_manager_consumed=true" \
  "stage573_component_runtime_text_input_demo_execution_contract_consumed=true" \
  "normalized_keyboard_text_intent_adapter_materialized=true" \
  "caret_movement_intent_adapter_materialized=true" \
  "selection_replacement_intent_adapter_materialized=true" \
  "composition_preedit_intent_adapter_materialized=true" \
  "text_input_adapter_bound_to_stage844_text_runtime_manager=true" \
  "text_input_adapter_bound_to_stage573_execution_contract=true" \
  "stage846_publishable_state_text_input_composition_preview_prepared=true" \
  "text_input_adapter_non_dispatching=true" \
  "input_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage844_publishable_state_text_runtime_manager_suite_passed=true" \
  "shared_publishable_text_runtime_manager_materialized=true" \
  "stage845_publishable_state_text_input_adapter_after_stage844_prepared=true"; do
  require_file_fact "$STAGE844_SUITE_PACKET" "$fact"
done

for fact in \
  "stage573_component_runtime_text_input_demo_execution_contract_owner_present=true" \
  "shared_text_input_demo_execution_contract_materialized=true" \
  "per_demo_text_input_event_execution_template_need_reduced=true"; do
  require_file_fact "$STAGE573_OWNER_LOG" "$fact"
done

{
  echo "stage845_publishable_state_text_input_adapter_suite_version=1"
  echo "stage844_suite_packet=$STAGE844_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage846_publishable_state_text_input_composition_preview_after_stage845"
  echo "stage845_publishable_state_text_input_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage845 publishable state text input adapter suite: route_classification=text_input_adapter"
echo "cjgui stage845 publishable state text input adapter suite: suite_packet_path=$SUITE_PACKET"
