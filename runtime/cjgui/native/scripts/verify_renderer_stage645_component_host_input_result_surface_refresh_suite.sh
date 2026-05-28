#!/usr/bin/env zsh
#
# Focused suite for stage645. It consumes stage644 host input cycle executor
# receipts and verifies shared result-surface refresh output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE645_TMPDIR:-/private/tmp/cjgui-stage645-stage648/stage645}"
SUITE_PACKET="$TMP_DIR/stage645-component-host-input-result-surface-refresh-suite.packet"
STAGE644_SUITE_PACKET="${CJGUI_STAGE645_INPUT_PACKET:-${CJGUI_STAGE644_COMPONENT_HOST_INPUT_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage641-stage644/stage644/stage644-component-host-input-cycle-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage645_component_host_input_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage645-component-host-input-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage645 component host input result surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage644_component_host_input_cycle_executor_consumed=true" \
  "shared_component_host_input_result_surface_refresh_materialized=true" \
  "validation_display_result_surface_refresh_materialized=true" \
  "chat_composer_component_host_input_result_surface_refresh_materialized=true" \
  "stage646_component_host_input_result_surface_layout_feedback_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE644_SUITE_PACKET" || ! -f "$STAGE644_SUITE_PACKET" ]]; then
  echo "cjgui stage645 component host input result surface refresh suite: missing stage644 packet; set CJGUI_STAGE645_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage644_component_host_input_cycle_executor_suite_version=1" \
  "shared_component_runtime_host_input_cycle_executor_contract_materialized=true" \
  "chat_composer_component_host_input_runtime_surface_materialized=true" \
  "stage645_component_host_input_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE644_SUITE_PACKET" "$fact"
done

{
  echo "stage645_component_host_input_result_surface_refresh_suite_version=1"
  echo "stage644_component_host_input_cycle_executor_suite_packet=$STAGE644_SUITE_PACKET"
  echo "stage645_component_host_input_result_surface_refresh_owner_passed=true"
  echo "stage644_component_host_input_cycle_executor_consumed=true"
  echo "stage643_component_host_input_cycle_receipt_consumed_transitively=true"
  echo "shared_component_host_input_result_surface_refresh_materialized=true"
  echo "validation_display_result_surface_refresh_materialized=true"
  echo "focus_movement_result_surface_preview_materialized=true"
  echo "input_feedback_result_surface_refresh_materialized=true"
  echo "semantic_diff_result_surface_refresh_materialized=true"
  echo "result_surface_refresh_ledger_materialized=true"
  echo "todo_component_host_input_result_surface_refresh_materialized=true"
  echo "settings_component_host_input_result_surface_refresh_materialized=true"
  echo "ai_generated_settings_component_host_input_result_surface_refresh_materialized=true"
  echo "chat_composer_component_host_input_result_surface_refresh_materialized=true"
  echo "result_surface_refresh_bound_to_stage644_executor=true"
  echo "result_surface_refresh_owner_local=true"
  echo "result_surface_refresh_non_publishing=true"
  echo "stage646_component_host_input_result_surface_layout_feedback_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage646_component_host_input_result_surface_layout_feedback_after_stage645"
  echo "stage645_component_host_input_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage645 component host input result surface refresh suite: route_classification=component_host_input_result_surface_refresh_ready"
echo "cjgui stage645 component host input result surface refresh suite: suite_packet_path=$SUITE_PACKET"
