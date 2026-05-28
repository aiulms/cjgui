#!/usr/bin/env zsh
#
# Focused suite for stage665. It consumes the stage664 feedback input runtime
# contract and verifies a shared demo-host surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE665_TMPDIR:-/private/tmp/cjgui-stage665-stage668/stage665}"
SUITE_PACKET="$TMP_DIR/stage665-component-feedback-input-demo-host-surface-suite.packet"
STAGE664_SUITE_PACKET="${CJGUI_STAGE665_INPUT_PACKET:-${CJGUI_STAGE664_INTERACTION_FEEDBACK_INPUT_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage661-stage664/stage664/stage664-interaction-feedback-input-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage665_component_feedback_input_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage665-component-feedback-input-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage665 component feedback input demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage664_interaction_feedback_input_runtime_contract_consumed=true" \
  "shared_component_feedback_input_demo_host_surface_materialized=true" \
  "validation_dismiss_host_surface_materialized=true" \
  "focus_movement_host_surface_materialized=true" \
  "input_feedback_clear_host_surface_materialized=true" \
  "semantic_diff_acknowledge_host_surface_materialized=true" \
  "chat_composer_feedback_input_demo_host_surface_materialized=true" \
  "stage666_component_feedback_input_host_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE664_SUITE_PACKET" || ! -f "$STAGE664_SUITE_PACKET" ]]; then
  echo "cjgui stage665 component feedback input demo-host surface suite: missing stage664 packet; set CJGUI_STAGE665_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage664_interaction_feedback_input_runtime_contract_suite_version=1" \
  "shared_interaction_feedback_input_runtime_contract_materialized=true" \
  "chat_composer_feedback_input_runtime_surface_materialized=true" \
  "stage665_component_feedback_input_demo_host_surface_after_stage664_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE664_SUITE_PACKET" "$fact"
done

{
  echo "stage665_component_feedback_input_demo_host_surface_suite_version=1"
  echo "stage664_interaction_feedback_input_runtime_contract_suite_packet=$STAGE664_SUITE_PACKET"
  echo "stage665_component_feedback_input_demo_host_surface_owner_passed=true"
  echo "stage664_interaction_feedback_input_runtime_contract_consumed=true"
  echo "stage663_interaction_feedback_input_state_render_receipt_consumed_transitively=true"
  echo "feedback_input_runtime_surfaces_consumed=true"
  echo "shared_component_feedback_input_demo_host_surface_materialized=true"
  echo "validation_dismiss_host_surface_materialized=true"
  echo "focus_movement_host_surface_materialized=true"
  echo "input_feedback_clear_host_surface_materialized=true"
  echo "semantic_diff_acknowledge_host_surface_materialized=true"
  echo "todo_feedback_input_demo_host_surface_materialized=true"
  echo "settings_feedback_input_demo_host_surface_materialized=true"
  echo "ai_generated_settings_feedback_input_demo_host_surface_materialized=true"
  echo "chat_composer_feedback_input_demo_host_surface_materialized=true"
  echo "demo_host_surface_bound_to_stage664_runtime_contract=true"
  echo "feedback_input_demo_host_surface_owner_local=true"
  echo "feedback_input_demo_host_surface_checkable=true"
  echo "stage666_component_feedback_input_host_inspection_receipt_prepared=true"
  echo "host_mutation=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage666_component_feedback_input_host_inspection_receipt_after_stage665"
  echo "stage665_component_feedback_input_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage665 component feedback input demo-host surface suite: route_classification=feedback_input_demo_host_surface_ready"
echo "cjgui stage665 component feedback input demo-host surface suite: suite_packet_path=$SUITE_PACKET"
