#!/usr/bin/env zsh
#
# Focused suite for stage702. It consumes stage701 and verifies the reusable
# text input component slot binding adapter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE702_TMPDIR:-/private/tmp/cjgui-stage701-stage704/stage702}"
SUITE_PACKET="$TMP_DIR/stage702-text-input-component-slot-binding-adapter-suite.packet"
STAGE701_SUITE_PACKET="${CJGUI_STAGE702_INPUT_PACKET:-${CJGUI_STAGE701_TEXT_INPUT_TIMELINE_COMPONENT_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage701-stage704/stage701/stage701-text-input-timeline-component-runtime-contract-suite.packet}}"
STAGE701_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage701_text_input_timeline_component_runtime_contract_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage702_text_input_component_slot_binding_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage702-text-input-component-slot-binding-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage702 text input component slot binding adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE701_SUITE_PACKET" ]]; then
  zsh "$STAGE701_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage701_text_input_timeline_component_runtime_contract_consumed=true" \
  "shared_text_input_component_slot_binding_adapter_materialized=true" \
  "component_slots_bound_to_timeline_action_intent=true" \
  "component_slots_bound_to_timeline_state_delta=true" \
  "component_slots_bound_to_render_result_refresh=true" \
  "component_action_state_render_binding_ledger_materialized=true" \
  "stage703_text_input_component_runtime_demo_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage701_text_input_timeline_component_runtime_contract_suite_version=1" \
  "shared_text_input_timeline_component_runtime_contract_materialized=true" \
  "text_value_component_slot_contract_materialized=true" \
  "stage702_text_input_component_slot_binding_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE701_SUITE_PACKET" "$fact"
done

{
  echo "stage702_text_input_component_slot_binding_adapter_suite_version=1"
  echo "stage701_text_input_timeline_component_runtime_contract_suite_packet=$STAGE701_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage703_text_input_component_runtime_demo_surface_refresh_after_stage702"
  echo "stage702_text_input_component_slot_binding_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage702 text input component slot binding adapter suite: route_classification=component_slot_binding_adapter_ready"
echo "cjgui stage702 text input component slot binding adapter suite: suite_packet_path=$SUITE_PACKET"
