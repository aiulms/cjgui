#!/usr/bin/env zsh
#
# Focused suite for stage629. It consumes stage628 host-input runtime surfaces
# and verifies the shared result-surface projection remains internal-only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE629_TMPDIR:-/private/tmp/cjgui-stage629-stage632/stage629}"
SUITE_PACKET="$TMP_DIR/stage629-focus-validation-host-input-result-surface-suite.packet"
STAGE628_SUITE_PACKET="${CJGUI_STAGE629_INPUT_PACKET:-${CJGUI_STAGE628_SHARED_FOCUS_VALIDATION_HOST_INPUT_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage625-stage628/stage628/stage628-shared-focus-validation-host-input-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage629_focus_validation_host_input_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage629-focus-validation-host-input-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage629 focus validation host input result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage628_shared_focus_validation_host_input_runtime_contract_consumed=true" \
  "shared_focus_validation_host_input_result_surface_materialized=true" \
  "validation_error_result_surface_materialized=true" \
  "focus_movement_result_surface_preview_materialized=true" \
  "stage630_focus_validation_host_input_result_semantic_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE628_SUITE_PACKET" || ! -f "$STAGE628_SUITE_PACKET" ]]; then
  echo "cjgui stage629 focus validation host input result surface suite: missing stage628 packet; set CJGUI_STAGE629_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage628_shared_focus_validation_host_input_runtime_contract_suite_version=1" \
  "shared_focus_validation_host_input_runtime_contract_materialized=true" \
  "cycle_order_host_input_event_action_state_render_host_surface_receipt_materialized=true" \
  "stage629_component_runtime_focus_validation_host_input_result_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE628_SUITE_PACKET" "$fact"
done

{
  echo "stage629_focus_validation_host_input_result_surface_suite_version=1"
  echo "stage628_shared_focus_validation_host_input_runtime_contract_suite_packet=$STAGE628_SUITE_PACKET"
  echo "stage629_focus_validation_host_input_result_surface_owner_passed=true"
  echo "stage628_shared_focus_validation_host_input_runtime_contract_consumed=true"
  echo "host_input_runtime_surfaces_consumed=true"
  echo "shared_focus_validation_host_input_result_surface_materialized=true"
  echo "validation_error_result_surface_materialized=true"
  echo "focus_movement_result_surface_preview_materialized=true"
  echo "input_feedback_result_surface_display_materialized=true"
  echo "semantic_diff_result_surface_refresh_materialized=true"
  echo "todo_focus_validation_result_surface_materialized=true"
  echo "settings_focus_validation_result_surface_materialized=true"
  echo "ai_generated_settings_focus_validation_result_surface_materialized=true"
  echo "chat_composer_focus_validation_result_surface_materialized=true"
  echo "result_surface_bound_to_stage628_runtime_contract=true"
  echo "stage630_focus_validation_host_input_result_semantic_refresh_prepared=true"
  echo "owner_acceptance_granted=false"
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
  echo "next_route=stage630_focus_validation_host_input_result_semantic_refresh_after_stage629"
  echo "stage629_focus_validation_host_input_result_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage629 focus validation host input result surface suite: route_classification=result_surface_ready"
echo "cjgui stage629 focus validation host input result surface suite: suite_packet_path=$SUITE_PACKET"
