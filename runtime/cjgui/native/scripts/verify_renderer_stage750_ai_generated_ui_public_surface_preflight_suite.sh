#!/usr/bin/env zsh
#
# Focused suite for stage750. It consumes stage749 and verifies that public
# surface preflight remains an internal compatibility boundary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE750_TMPDIR:-/private/tmp/cjgui-stage749-stage752/stage750}"
SUITE_PACKET="$TMP_DIR/stage750-ai-generated-ui-public-surface-preflight-suite.packet"
STAGE749_SUITE_PACKET="${CJGUI_STAGE750_INPUT_PACKET:-${CJGUI_STAGE749_AI_GENERATED_UI_OWNER_ACCEPTANCE_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage749-stage752/stage749/stage749-ai-generated-ui-owner-acceptance-preflight-suite.packet}}"
STAGE749_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage749_ai_generated_ui_owner_acceptance_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage750_ai_generated_ui_public_surface_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage750-ai-generated-ui-public-surface-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage750 ai generated ui public surface preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE749_SUITE_PACKET" ]] || ! grep -F "stage749_ai_generated_ui_owner_acceptance_preflight_suite_passed=true" "$STAGE749_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE749_TMPDIR="$TMP_DIR/stage749" zsh "$STAGE749_SUITE_SCRIPT" >/dev/null
  STAGE749_SUITE_PACKET="$TMP_DIR/stage749/stage749-ai-generated-ui-owner-acceptance-preflight-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage749_ai_generated_ui_owner_acceptance_preflight_consumed=true" \
  "stage748_ai_generated_ui_runtime_manager_consumed_transitively=true" \
  "internal_public_surface_boundary_materialized=true" \
  "compatibility_note_ledger_materialized=true" \
  "public_api_rejection_reason_ledger_materialized=true" \
  "public_surface_preflight_bound_to_owner_acceptance_preflight=true" \
  "stage751_ai_generated_ui_acceptance_demo_host_surface_prepared=true" \
  "owner_acceptance_granted=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage749_ai_generated_ui_owner_acceptance_preflight_suite_passed=true" \
  "owner_acceptance_preflight_rows_materialized=true" \
  "owner_acceptance_candidate_ledger_materialized=true" \
  "stage750_ai_generated_ui_public_surface_preflight_prepared=true" \
  "owner_acceptance_granted=false" \
  "public_component_api_added=false"; do
  require_file_fact "$STAGE749_SUITE_PACKET" "$fact"
done

{
  echo "stage750_ai_generated_ui_public_surface_preflight_suite_version=1"
  echo "stage749_ai_generated_ui_owner_acceptance_preflight_suite_packet=$STAGE749_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage750_ai_generated_ui_public_surface_preflight_suite_passed=true"
  echo "next_route=stage751_ai_generated_ui_acceptance_demo_host_surface_after_stage750"
} > "$SUITE_PACKET"

echo "cjgui stage750 ai generated ui public surface preflight suite: route_classification=public_surface_preflight_ready"
echo "cjgui stage750 ai generated ui public surface preflight suite: suite_packet_path=$SUITE_PACKET"
