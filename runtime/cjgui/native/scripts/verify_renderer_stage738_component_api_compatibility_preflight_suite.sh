#!/usr/bin/env zsh
#
# Focused suite for stage738. It consumes stage737 and verifies public surface
# compatibility preflight without adding a stable public API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE738_TMPDIR:-/private/tmp/cjgui-stage737-stage740/stage738}"
SUITE_PACKET="$TMP_DIR/stage738-component-api-compatibility-preflight-suite.packet"
STAGE737_SUITE_PACKET="${CJGUI_STAGE738_INPUT_PACKET:-${CJGUI_STAGE737_COMPONENT_STATE_STORE_PUBLIC_API_INTERNAL_SHAPE_SUITE_PACKET:-/private/tmp/cjgui-stage737-stage740/stage737/stage737-component-state-store-public-api-internal-shape-suite.packet}}"
STAGE737_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage737_component_state_store_public_api_internal_shape_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage738_component_api_compatibility_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage738-component-api-compatibility-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage738 component api compatibility preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE737_SUITE_PACKET" ]] || ! grep -F "stage737_component_state_store_public_api_internal_shape_suite_passed=true" "$STAGE737_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE737_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage737_component_state_store_public_api_internal_shape_consumed=true" \
  "component_api_compatibility_ledger_materialized=true" \
  "public_surface_preflight_boundary_materialized=true" \
  "component_api_versioning_note_materialized=true" \
  "public_api_rejection_reason_ledger_materialized=true" \
  "stable_public_api_unexpanded=true" \
  "stage739_component_api_demo_host_authoring_surface_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage737_component_state_store_public_api_internal_shape_suite_version=1" \
  "internal_component_api_shape_descriptor_materialized=true" \
  "component_commit_capability_shape_materialized=true" \
  "stage738_component_api_compatibility_preflight_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE737_SUITE_PACKET" "$fact"
done

{
  echo "stage738_component_api_compatibility_preflight_suite_version=1"
  echo "stage737_component_state_store_public_api_internal_shape_suite_packet=$STAGE737_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage739_component_api_demo_host_authoring_surface_after_stage738"
  echo "stage738_component_api_compatibility_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage738 component api compatibility preflight suite: route_classification=component_api_compatibility_preflight_ready"
echo "cjgui stage738 component api compatibility preflight suite: suite_packet_path=$SUITE_PACKET"
