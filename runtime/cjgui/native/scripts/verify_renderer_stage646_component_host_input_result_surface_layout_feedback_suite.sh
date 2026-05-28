#!/usr/bin/env zsh
#
# Focused suite for stage646. It consumes stage645 result-surface refresh and
# verifies shared layout/style/focus feedback preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE646_TMPDIR:-/private/tmp/cjgui-stage645-stage648/stage646}"
SUITE_PACKET="$TMP_DIR/stage646-component-host-input-result-surface-layout-feedback-suite.packet"
STAGE645_SUITE_PACKET="${CJGUI_STAGE646_INPUT_PACKET:-${CJGUI_STAGE645_COMPONENT_HOST_INPUT_RESULT_SURFACE_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage645-stage648/stage645/stage645-component-host-input-result-surface-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage646_component_host_input_result_surface_layout_feedback_owner.sh"
OWNER_LOG="$TMP_DIR/stage646-component-host-input-result-surface-layout-feedback-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage646 component host input result surface layout feedback suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage645_component_host_input_result_surface_refresh_consumed=true" \
  "shared_result_surface_layout_feedback_resolver_materialized=true" \
  "validation_message_layout_slot_materialized=true" \
  "chat_composer_result_surface_layout_feedback_materialized=true" \
  "stage647_component_host_input_result_surface_host_inspection_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE645_SUITE_PACKET" || ! -f "$STAGE645_SUITE_PACKET" ]]; then
  echo "cjgui stage646 component host input result surface layout feedback suite: missing stage645 packet; set CJGUI_STAGE646_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage645_component_host_input_result_surface_refresh_suite_version=1" \
  "shared_component_host_input_result_surface_refresh_materialized=true" \
  "chat_composer_component_host_input_result_surface_refresh_materialized=true" \
  "stage646_component_host_input_result_surface_layout_feedback_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE645_SUITE_PACKET" "$fact"
done

{
  echo "stage646_component_host_input_result_surface_layout_feedback_suite_version=1"
  echo "stage645_component_host_input_result_surface_refresh_suite_packet=$STAGE645_SUITE_PACKET"
  echo "stage646_component_host_input_result_surface_layout_feedback_owner_passed=true"
  echo "stage645_component_host_input_result_surface_refresh_consumed=true"
  echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
  echo "shared_result_surface_layout_feedback_resolver_materialized=true"
  echo "validation_message_layout_slot_materialized=true"
  echo "focus_ring_style_token_preview_materialized=true"
  echo "input_feedback_affordance_preview_materialized=true"
  echo "semantic_refresh_layout_trace_materialized=true"
  echo "todo_result_surface_layout_feedback_materialized=true"
  echo "settings_result_surface_layout_feedback_materialized=true"
  echo "ai_generated_settings_result_surface_layout_feedback_materialized=true"
  echo "chat_composer_result_surface_layout_feedback_materialized=true"
  echo "layout_feedback_bound_to_stage645_refresh=true"
  echo "layout_feedback_preview_only=true"
  echo "stage647_component_host_input_result_surface_host_inspection_prepared=true"
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
  echo "next_route=stage647_component_host_input_result_surface_host_inspection_after_stage646"
  echo "stage646_component_host_input_result_surface_layout_feedback_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage646 component host input result surface layout feedback suite: route_classification=result_surface_layout_feedback_ready"
echo "cjgui stage646 component host input result surface layout feedback suite: suite_packet_path=$SUITE_PACKET"
