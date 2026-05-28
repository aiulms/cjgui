#!/usr/bin/env zsh
#
# Focused suite for stage638. It consumes stage637 layout/focus previews and
# verifies the checkable execution receipt shape.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE638_TMPDIR:-/private/tmp/cjgui-stage637-stage640/stage638}"
SUITE_PACKET="$TMP_DIR/stage638-result-surface-layout-focus-receipt-suite.packet"
STAGE637_SUITE_PACKET="${CJGUI_STAGE638_INPUT_PACKET:-${CJGUI_STAGE637_RESULT_SURFACE_LAYOUT_FOCUS_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage637-stage640/stage637/stage637-result-surface-layout-focus-preview-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage638_result_surface_layout_focus_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage638-result-surface-layout-focus-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage638 result surface layout focus receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage637_result_surface_layout_focus_preview_consumed=true" \
  "shared_layout_focus_execution_receipt_materialized=true" \
  "result_surface_text_run_receipt_materialized=true" \
  "chat_composer_layout_focus_execution_receipt_materialized=true" \
  "stage639_result_surface_demo_host_inspection_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE637_SUITE_PACKET" || ! -f "$STAGE637_SUITE_PACKET" ]]; then
  echo "cjgui stage638 result surface layout focus receipt suite: missing stage637 packet; set CJGUI_STAGE638_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage637_result_surface_layout_focus_preview_suite_version=1" \
  "shared_result_surface_interaction_layout_preview_materialized=true" \
  "shared_result_surface_interaction_focus_preview_materialized=true" \
  "stage638_result_surface_layout_focus_execution_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE637_SUITE_PACKET" "$fact"
done

{
  echo "stage638_result_surface_layout_focus_receipt_suite_version=1"
  echo "stage637_result_surface_layout_focus_preview_suite_packet=$STAGE637_SUITE_PACKET"
  echo "stage638_result_surface_layout_focus_receipt_owner_passed=true"
  echo "stage637_result_surface_layout_focus_preview_consumed=true"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed_transitively=true"
  echo "shared_layout_focus_execution_receipt_materialized=true"
  echo "result_surface_text_run_receipt_materialized=true"
  echo "result_surface_style_token_receipt_materialized=true"
  echo "result_surface_focus_traversal_receipt_materialized=true"
  echo "todo_layout_focus_execution_receipt_materialized=true"
  echo "settings_layout_focus_execution_receipt_materialized=true"
  echo "ai_generated_settings_layout_focus_execution_receipt_materialized=true"
  echo "chat_composer_layout_focus_execution_receipt_materialized=true"
  echo "layout_focus_receipt_bound_to_stage637_preview=true"
  echo "stage639_result_surface_demo_host_inspection_prepared=true"
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
  echo "next_route=stage639_result_surface_demo_host_inspection_after_stage638"
  echo "stage638_result_surface_layout_focus_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage638 result surface layout focus receipt suite: route_classification=result_surface_layout_focus_receipt_ready"
echo "cjgui stage638 result surface layout focus receipt suite: suite_packet_path=$SUITE_PACKET"
