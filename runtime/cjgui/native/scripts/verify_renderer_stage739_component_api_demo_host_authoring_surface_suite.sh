#!/usr/bin/env zsh
#
# Focused suite for stage739. It consumes stage738 and verifies the checkable
# demo-host authoring surface for internal component API shape review.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE739_TMPDIR:-/private/tmp/cjgui-stage737-stage740/stage739}"
SUITE_PACKET="$TMP_DIR/stage739-component-api-demo-host-authoring-surface-suite.packet"
STAGE738_SUITE_PACKET="${CJGUI_STAGE739_INPUT_PACKET:-${CJGUI_STAGE738_COMPONENT_API_COMPATIBILITY_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage737-stage740/stage738/stage738-component-api-compatibility-preflight-suite.packet}}"
STAGE738_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage738_component_api_compatibility_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage739_component_api_demo_host_authoring_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage739-component-api-demo-host-authoring-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage739 component api demo host authoring surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE738_SUITE_PACKET" ]] || ! grep -F "stage738_component_api_compatibility_preflight_suite_passed=true" "$STAGE738_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE738_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage738_component_api_compatibility_preflight_consumed=true" \
  "component_api_demo_host_authoring_surface_materialized=true" \
  "api_shape_field_inspection_rows_materialized=true" \
  "api_props_state_action_port_inspection_rows_materialized=true" \
  "api_compatibility_review_rows_materialized=true" \
  "api_authoring_render_command_receipt_materialized=true" \
  "stage740_component_api_internal_shape_runtime_manager_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage738_component_api_compatibility_preflight_suite_version=1" \
  "component_api_compatibility_ledger_materialized=true" \
  "public_surface_preflight_boundary_materialized=true" \
  "stable_public_api_unexpanded=true" \
  "stage739_component_api_demo_host_authoring_surface_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE738_SUITE_PACKET" "$fact"
done

{
  echo "stage739_component_api_demo_host_authoring_surface_suite_version=1"
  echo "stage738_component_api_compatibility_preflight_suite_packet=$STAGE738_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage740_component_api_internal_shape_runtime_manager_after_stage739"
  echo "stage739_component_api_demo_host_authoring_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage739 component api demo host authoring surface suite: route_classification=component_api_authoring_surface_ready"
echo "cjgui stage739 component api demo host authoring surface suite: suite_packet_path=$SUITE_PACKET"
