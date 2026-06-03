#!/usr/bin/env zsh
#
# Focused suite for stage703. It consumes stage702 and verifies component
# runtime demo surface/result refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE703_TMPDIR:-/private/tmp/cjgui-stage701-stage704/stage703}"
SUITE_PACKET="$TMP_DIR/stage703-text-input-component-runtime-demo-surface-refresh-suite.packet"
STAGE702_SUITE_PACKET="${CJGUI_STAGE703_INPUT_PACKET:-${CJGUI_STAGE702_TEXT_INPUT_COMPONENT_SLOT_BINDING_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage701-stage704/stage702/stage702-text-input-component-slot-binding-adapter-suite.packet}}"
STAGE702_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage702_text_input_component_slot_binding_adapter_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage703_text_input_component_runtime_demo_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage703-text-input-component-runtime-demo-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage703 text input component runtime demo surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE702_SUITE_PACKET" ]]; then
  zsh "$STAGE702_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage702_text_input_component_slot_binding_adapter_consumed=true" \
  "shared_text_input_component_runtime_demo_surface_refresh_materialized=true" \
  "component_runtime_result_surface_refresh_materialized=true" \
  "component_runtime_semantic_diff_explain_materialized=true" \
  "component_runtime_feedback_surface_refresh_materialized=true" \
  "component_runtime_focus_surface_refresh_materialized=true" \
  "stage704_text_input_component_runtime_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage702_text_input_component_slot_binding_adapter_suite_version=1" \
  "shared_text_input_component_slot_binding_adapter_materialized=true" \
  "component_action_state_render_binding_ledger_materialized=true" \
  "stage703_text_input_component_runtime_demo_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE702_SUITE_PACKET" "$fact"
done

{
  echo "stage703_text_input_component_runtime_demo_surface_refresh_suite_version=1"
  echo "stage702_text_input_component_slot_binding_adapter_suite_packet=$STAGE702_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage704_text_input_component_runtime_cycle_executor_after_stage703"
  echo "stage703_text_input_component_runtime_demo_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage703 text input component runtime demo surface refresh suite: route_classification=component_runtime_demo_surface_refresh_ready"
echo "cjgui stage703 text input component runtime demo surface refresh suite: suite_packet_path=$SUITE_PACKET"
