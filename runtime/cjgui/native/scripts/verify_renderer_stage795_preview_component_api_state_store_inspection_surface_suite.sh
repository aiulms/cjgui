#!/usr/bin/env zsh
#
# Focused suite for stage795. It consumes stage794 and records state-store
# inspection/result surfaces across reusable demo classes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE795_TMPDIR:-/private/tmp/cjgui-stage793-stage796/stage795}"
SUITE_PACKET="$TMP_DIR/stage795-preview-component-api-state-store-inspection-surface-suite.packet"
STAGE794_SUITE_PACKET="${CJGUI_STAGE795_INPUT_PACKET:-${CJGUI_STAGE794_PREVIEW_COMPONENT_API_STATE_STORE_DRY_RUN_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage793-stage796/stage794/stage794-preview-component-api-state-store-dry-run-executor-suite.packet}}"
STAGE794_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage794_preview_component_api_state_store_dry_run_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage795_preview_component_api_state_store_inspection_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage795-preview-component-api-state-store-inspection-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage795 preview component api state-store inspection surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE794_SUITE_PACKET" ]] || ! grep -F "stage794_preview_component_api_state_store_dry_run_executor_suite_passed=true" "$STAGE794_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE794_TMPDIR="$TMP_DIR/stage794" zsh "$STAGE794_SUITE_SCRIPT" >/dev/null
  STAGE794_SUITE_PACKET="$TMP_DIR/stage794/stage794-preview-component-api-state-store-dry-run-executor-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage794_preview_component_api_state_store_dry_run_executor_consumed=true" \
  "state_store_dry_run_host_inspection_rows_materialized=true" \
  "state_store_dry_run_result_surface_refresh_materialized=true" \
  "state_store_mutation_diff_receipt_materialized=true" \
  "state_store_rollback_preview_receipt_materialized=true" \
  "todo_state_store_dry_run_surface_materialized=true" \
  "settings_state_store_dry_run_surface_materialized=true" \
  "ai_generated_settings_state_store_dry_run_surface_materialized=true" \
  "chat_composer_state_store_dry_run_surface_materialized=true" \
  "file_browser_state_store_dry_run_surface_materialized=true" \
  "inspection_surface_bound_to_stage794_dry_run_executor=true" \
  "stage796_preview_component_api_state_store_bridge_runtime_manager_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage794_preview_component_api_state_store_dry_run_executor_suite_passed=true" \
  "component_state_store_dry_run_executor_materialized=true" \
  "stage795_preview_component_api_state_store_inspection_surface_prepared=true"; do
  require_file_fact "$STAGE794_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage795_preview_component_api_state_store_inspection_surface.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage795 preview component api state-store inspection surface suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage795 preview component api state-store inspection surface suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage795_preview_component_api_state_store_inspection_surface_suite_version=1"
  echo "stage794_preview_component_api_state_store_dry_run_executor_suite_packet=$STAGE794_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage795_public_foreign_scan_passed=true"
  echo "stage795_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage796_preview_component_api_state_store_bridge_runtime_manager_after_stage795"
  echo "stage795_preview_component_api_state_store_inspection_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage795 preview component api state-store inspection surface suite: route_classification=state_store_inspection_surface"
echo "cjgui stage795 preview component api state-store inspection surface suite: suite_packet_path=$SUITE_PACKET"
