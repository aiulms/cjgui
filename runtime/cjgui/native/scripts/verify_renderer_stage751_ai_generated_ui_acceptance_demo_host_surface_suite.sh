#!/usr/bin/env zsh
#
# Focused suite for stage751. It consumes stage750 and verifies the
# AI-generated UI acceptance demo-host surface stays checkable and non-mutating.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE751_TMPDIR:-/private/tmp/cjgui-stage749-stage752/stage751}"
SUITE_PACKET="$TMP_DIR/stage751-ai-generated-ui-acceptance-demo-host-surface-suite.packet"
STAGE750_SUITE_PACKET="${CJGUI_STAGE751_INPUT_PACKET:-${CJGUI_STAGE750_AI_GENERATED_UI_PUBLIC_SURFACE_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage749-stage752/stage750/stage750-ai-generated-ui-public-surface-preflight-suite.packet}}"
STAGE750_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage750_ai_generated_ui_public_surface_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage751_ai_generated_ui_acceptance_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage751-ai-generated-ui-acceptance-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage751 ai generated ui acceptance demo host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE750_SUITE_PACKET" ]] || ! grep -F "stage750_ai_generated_ui_public_surface_preflight_suite_passed=true" "$STAGE750_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE750_TMPDIR="$TMP_DIR/stage750" zsh "$STAGE750_SUITE_SCRIPT" >/dev/null
  STAGE750_SUITE_PACKET="$TMP_DIR/stage750/stage750-ai-generated-ui-public-surface-preflight-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage750_ai_generated_ui_public_surface_preflight_consumed=true" \
  "acceptance_demo_host_inspection_rows_materialized=true" \
  "acceptance_result_surface_preview_materialized=true" \
  "acceptance_render_command_preview_receipt_materialized=true" \
  "acceptance_probe_input_contract_materialized=true" \
  "acceptance_demo_host_surface_bound_to_public_surface_preflight=true" \
  "stage752_ai_generated_ui_owner_acceptance_runtime_manager_prepared=true" \
  "owner_acceptance_granted=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage750_ai_generated_ui_public_surface_preflight_suite_passed=true" \
  "internal_public_surface_boundary_materialized=true" \
  "compatibility_note_ledger_materialized=true" \
  "public_api_rejection_reason_ledger_materialized=true" \
  "stage751_ai_generated_ui_acceptance_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE750_SUITE_PACKET" "$fact"
done

{
  echo "stage751_ai_generated_ui_acceptance_demo_host_surface_suite_version=1"
  echo "stage750_ai_generated_ui_public_surface_preflight_suite_packet=$STAGE750_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage751_ai_generated_ui_acceptance_demo_host_surface_suite_passed=true"
  echo "next_route=stage752_ai_generated_ui_owner_acceptance_runtime_manager_after_stage751"
} > "$SUITE_PACKET"

echo "cjgui stage751 ai generated ui acceptance demo host surface suite: route_classification=acceptance_demo_host_surface_ready"
echo "cjgui stage751 ai generated ui acceptance demo host surface suite: suite_packet_path=$SUITE_PACKET"
