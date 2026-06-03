#!/usr/bin/env zsh
#
# Focused suite for stage737. It consumes stage736 and verifies the internal
# component API shape stays pre-public and dry-run only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE737_TMPDIR:-/private/tmp/cjgui-stage737-stage740/stage737}"
SUITE_PACKET="$TMP_DIR/stage737-component-state-store-public-api-internal-shape-suite.packet"
STAGE736_SUITE_PACKET="${CJGUI_STAGE737_INPUT_PACKET:-${CJGUI_STAGE736_COMPONENT_STATE_STORE_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage733-stage736/stage736/stage736-component-state-store-commit-runtime-manager-suite.packet}}"
STAGE736_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage736_component_state_store_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage737_component_state_store_public_api_internal_shape_owner.sh"
OWNER_LOG="$TMP_DIR/stage737-component-state-store-public-api-internal-shape-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage737 component state store public api internal shape suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE736_SUITE_PACKET" ]] || ! grep -F "stage736_component_state_store_commit_runtime_manager_suite_passed=true" "$STAGE736_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE736_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage736_component_state_store_commit_runtime_manager_consumed=true" \
  "internal_component_api_shape_descriptor_materialized=true" \
  "component_props_shape_ledger_materialized=true" \
  "component_state_slot_shape_ledger_materialized=true" \
  "component_event_port_shape_ledger_materialized=true" \
  "component_commit_capability_shape_materialized=true" \
  "stage738_component_api_compatibility_preflight_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage736_component_state_store_commit_runtime_manager_suite_version=1" \
  "shared_component_state_store_commit_runtime_manager_materialized=true" \
  "component_state_store_commit_runtime_contract_materialized=true" \
  "stage737_component_state_store_public_api_internal_shape_prepared=true" \
  "public_component_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE736_SUITE_PACKET" "$fact"
done

{
  echo "stage737_component_state_store_public_api_internal_shape_suite_version=1"
  echo "stage736_component_state_store_commit_runtime_manager_suite_packet=$STAGE736_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage738_component_api_compatibility_preflight_after_stage737"
  echo "stage737_component_state_store_public_api_internal_shape_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage737 component state store public api internal shape suite: route_classification=component_api_internal_shape_ready"
echo "cjgui stage737 component state store public api internal shape suite: suite_packet_path=$SUITE_PACKET"
