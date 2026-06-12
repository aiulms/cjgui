#!/usr/bin/env zsh
#
# Focused suite for stage829. It consumes stage828 and records the owner-local
# publishable component state model.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE829_TMPDIR:-/private/tmp/cjgui-stage829-stage832/stage829}"
SUITE_PACKET="$TMP_DIR/stage829-component-state-store-publishable-state-model-suite.packet"
STAGE828_SUITE_PACKET="${CJGUI_STAGE829_INPUT_PACKET:-${CJGUI_STAGE828_COMMIT_FIRST_SLICE_PUBLICATION_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage829-stage832/stage828/stage828-commit-first-slice-publication-runtime-manager-suite.packet}}"
STAGE828_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage828_commit_first_slice_publication_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_owner.sh"
OWNER_LOG="$TMP_DIR/stage829-component-state-store-publishable-state-model-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage829 component state-store publishable state model suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE828_SUITE_PACKET" ]] || ! grep -F "stage828_commit_first_slice_publication_runtime_manager_suite_passed=true" "$STAGE828_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE828_TMPDIR="$TMP_DIR/stage828" zsh "$STAGE828_SUITE_SCRIPT" >/dev/null
  STAGE828_SUITE_PACKET="$TMP_DIR/stage828/stage828-commit-first-slice-publication-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage828_commit_first_slice_publication_runtime_manager_consumed=true" \
  "stage827_commit_first_slice_publication_demo_host_surface_consumed_transitively=true" \
  "shared_publication_runtime_manager_consumed=true" \
  "owner_local_publishable_state_model_materialized=true" \
  "component_state_identity_ledger_materialized=true" \
  "draft_visibility_state_projection_materialized=true" \
  "publishable_state_compatibility_ledger_materialized=true" \
  "publishable_state_model_bound_to_stage828_publication_runtime_manager=true" \
  "stage830_component_state_store_slot_value_model_prepared=true" \
  "new_public_surface_added=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage828_commit_first_slice_publication_runtime_manager_suite_passed=true" \
  "shared_publication_runtime_manager_materialized=true" \
  "file_browser_publication_runtime_surface_materialized=true" \
  "stage829_component_state_store_publishable_state_model_after_stage828_prepared=true"; do
  require_file_fact "$STAGE828_SUITE_PACKET" "$fact"
done

{
  echo "stage829_component_state_store_publishable_state_model_suite_version=1"
  echo "stage828_suite_packet=$STAGE828_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage830_component_state_store_slot_value_model_after_stage829"
  echo "stage829_component_state_store_publishable_state_model_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage829 component state-store publishable state model suite: route_classification=publishable_state_model"
echo "cjgui stage829 component state-store publishable state model suite: suite_packet_path=$SUITE_PACKET"
