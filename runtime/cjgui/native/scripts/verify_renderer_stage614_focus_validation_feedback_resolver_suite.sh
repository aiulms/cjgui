#!/usr/bin/env zsh
#
# Focused suite for stage614. It consumes the stage613 manager packet and
# verifies shared text/style/input feedback resolution.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE614_TMPDIR:-/private/tmp/cjgui-stage613-stage616/stage614}"
SUITE_PACKET="$TMP_DIR/stage614-focus-validation-feedback-resolver-suite.packet"
STAGE613_SUITE_PACKET="${CJGUI_STAGE614_INPUT_PACKET:-${CJGUI_STAGE613_FOCUS_VALIDATION_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage613-stage616/stage613/stage613-focus-validation-manager-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage614_focus_validation_feedback_resolver_owner.sh"
OWNER_LOG="$TMP_DIR/stage614-focus-validation-feedback-resolver-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage614 focus validation feedback resolver suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage613_focus_validation_manager_consumed=true" \
  "shared_focus_validation_feedback_resolver_materialized=true" \
  "validation_message_text_run_materialized=true" \
  "focus_ring_style_token_materialized=true" \
  "chat_composer_focus_validation_feedback_surface_materialized=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE613_SUITE_PACKET" || ! -f "$STAGE613_SUITE_PACKET" ]]; then
  echo "cjgui stage614 focus validation feedback resolver suite: missing stage613 packet; set CJGUI_STAGE614_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage613_focus_validation_manager_suite_version=1" \
  "shared_focus_validation_manager_contract_materialized=true" \
  "validation_state_ledger_materialized=true" \
  "stage614_focus_validation_feedback_resolver_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE613_SUITE_PACKET" "$fact"
done

{
  echo "stage614_focus_validation_feedback_resolver_suite_version=1"
  echo "stage613_focus_validation_manager_suite_packet=$STAGE613_SUITE_PACKET"
  echo "stage614_focus_validation_feedback_resolver_owner_passed=true"
  echo "stage613_focus_validation_manager_consumed=true"
  echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed_transitively=true"
  echo "shared_focus_validation_feedback_resolver_materialized=true"
  echo "validation_message_text_run_materialized=true"
  echo "focus_ring_style_token_materialized=true"
  echo "input_feedback_affordance_materialized=true"
  echo "todo_focus_validation_feedback_surface_materialized=true"
  echo "settings_focus_validation_feedback_surface_materialized=true"
  echo "ai_generated_settings_focus_validation_feedback_surface_materialized=true"
  echo "chat_composer_focus_validation_feedback_surface_materialized=true"
  echo "stage615_focus_validation_demo_host_receipt_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage614_focus_validation_feedback_resolver_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage614 focus validation feedback resolver suite: route_classification=focus_validation_feedback_resolver_ready"
echo "cjgui stage614 focus validation feedback resolver suite: suite_packet_path=$SUITE_PACKET"
