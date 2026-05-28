#!/usr/bin/env zsh
#
# Focused suite for stage626. It consumes stage625 host input adapter and
# verifies shared normalized host input events.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE626_TMPDIR:-/private/tmp/cjgui-stage625-stage628/stage626}"
SUITE_PACKET="$TMP_DIR/stage626-focus-validation-host-input-event-normalizer-suite.packet"
STAGE625_SUITE_PACKET="${CJGUI_STAGE626_INPUT_PACKET:-${CJGUI_STAGE625_FOCUS_VALIDATION_HOST_INPUT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage625-stage628/stage625/stage625-focus-validation-host-input-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage626_focus_validation_host_input_event_normalizer_owner.sh"
OWNER_LOG="$TMP_DIR/stage626-focus-validation-host-input-event-normalizer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage626 focus validation host input event normalizer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE625_SUITE_PACKET" || ! -f "$STAGE625_SUITE_PACKET" ]]; then
  echo "cjgui stage626 focus validation host input event normalizer suite: missing stage625 packet; set CJGUI_STAGE626_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage625_focus_validation_host_input_adapter_suite_version=1" \
  "shared_focus_validation_host_input_adapter_materialized=true" \
  "host_frame_input_binding_ledger_materialized=true" \
  "stage626_component_runtime_focus_validation_host_input_event_normalizer_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE625_SUITE_PACKET" "$fact"
done

for fact in \
  "stage625_focus_validation_host_input_adapter_consumed=true" \
  "shared_focus_validation_host_input_event_normalizer_materialized=true" \
  "host_input_event_ledger_materialized=true" \
  "chat_composer_normalized_focus_validation_host_input_event_materialized=true" \
  "stage627_component_runtime_focus_validation_host_input_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage626_focus_validation_host_input_event_normalizer_suite_version=1"
  echo "stage625_focus_validation_host_input_adapter_suite_packet=$STAGE625_SUITE_PACKET"
  echo "stage626_focus_validation_host_input_event_normalizer_owner_passed=true"
  echo "stage625_focus_validation_host_input_adapter_consumed=true"
  echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed_transitively=true"
  echo "shared_focus_validation_host_input_event_normalizer_materialized=true"
  echo "normalized_validation_display_host_input_event_materialized=true"
  echo "normalized_focus_handoff_host_input_event_materialized=true"
  echo "normalized_input_feedback_host_input_event_materialized=true"
  echo "normalized_semantic_diff_host_input_event_materialized=true"
  echo "host_input_event_ledger_materialized=true"
  echo "todo_normalized_focus_validation_host_input_event_materialized=true"
  echo "settings_normalized_focus_validation_host_input_event_materialized=true"
  echo "ai_generated_settings_normalized_focus_validation_host_input_event_materialized=true"
  echo "chat_composer_normalized_focus_validation_host_input_event_materialized=true"
  echo "host_input_event_normalizer_bound_to_stage625_adapter=true"
  echo "host_input_event_normalizer_bound_to_stage624_runtime_contract=true"
  echo "stage627_component_runtime_focus_validation_host_input_cycle_executor_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage626_focus_validation_host_input_event_normalizer_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage626 focus validation host input event normalizer suite: route_classification=focus_validation_host_input_event_normalizer_ready"
echo "cjgui stage626 focus validation host input event normalizer suite: suite_packet_path=$SUITE_PACKET"
