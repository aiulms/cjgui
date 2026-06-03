#!/usr/bin/env zsh
#
# Focused suite for stage759. It consumes stage758 and verifies Todo/settings
# demo surfaces consume the experimental public preview API shape.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE759_TMPDIR:-/private/tmp/cjgui-stage757-stage760/stage759}"
SUITE_PACKET="$TMP_DIR/stage759-minimal-public-preview-api-demo-consumption-suite.packet"
STAGE758_SUITE_PACKET="${CJGUI_STAGE759_INPUT_PACKET:-${CJGUI_STAGE758_MINIMAL_PUBLIC_PREVIEW_API_DECLARATION_SUITE_PACKET:-/private/tmp/cjgui-stage757-stage760/stage758/stage758-minimal-public-preview-api-declaration-suite.packet}}"
STAGE758_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage758_minimal_public_preview_api_declaration_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage759_minimal_public_preview_api_demo_consumption_owner.sh"
OWNER_LOG="$TMP_DIR/stage759-minimal-public-preview-api-demo-consumption-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage759 minimal public preview api demo consumption suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE758_SUITE_PACKET" ]] || ! grep -F "stage758_minimal_public_preview_api_declaration_suite_passed=true" "$STAGE758_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE758_TMPDIR="$TMP_DIR/stage758" zsh "$STAGE758_SUITE_SCRIPT" >/dev/null
  STAGE758_SUITE_PACKET="$TMP_DIR/stage758/stage758-minimal-public-preview-api-declaration-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage758_minimal_public_preview_api_declaration_consumed=true" \
  "cjguiExperimentalComponentPreviewApiReady_consumed=true" \
  "todo_public_preview_api_demo_surface_materialized=true" \
  "settings_public_preview_api_demo_surface_materialized=true" \
  "demo_consumption_bound_to_public_preview_api_declaration=true" \
  "public_component_api_added=true" \
  "stable_public_api_added=false" \
  "public_c_abi_added=false" \
  "stage760_minimal_public_preview_api_public_scan_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage758_minimal_public_preview_api_declaration_suite_passed=true" \
  "public_surface_cjguiExperimentalComponentPreviewApiReady_materialized=true" \
  "public_component_api_added=true" \
  "stable_public_api_added=false"; do
  require_file_fact "$STAGE758_SUITE_PACKET" "$fact"
done

{
  echo "stage759_minimal_public_preview_api_demo_consumption_suite_version=1"
  echo "stage758_minimal_public_preview_api_declaration_suite_packet=$STAGE758_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage759_minimal_public_preview_api_demo_consumption_suite_passed=true"
  echo "next_route=stage760_minimal_public_preview_api_public_scan_contract_after_stage759"
} > "$SUITE_PACKET"

echo "cjgui stage759 minimal public preview api demo consumption suite: route_classification=preview_api_demo_consumption_ready"
echo "cjgui stage759 minimal public preview api demo consumption suite: suite_packet_path=$SUITE_PACKET"
