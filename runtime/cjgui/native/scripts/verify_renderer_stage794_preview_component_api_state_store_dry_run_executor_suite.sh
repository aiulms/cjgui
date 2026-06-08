#!/usr/bin/env zsh
#
# Focused suite for stage794. It consumes stage793 and records the component
# state-store dry-run executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE794_TMPDIR:-/private/tmp/cjgui-stage793-stage796/stage794}"
SUITE_PACKET="$TMP_DIR/stage794-preview-component-api-state-store-dry-run-executor-suite.packet"
STAGE793_SUITE_PACKET="${CJGUI_STAGE794_INPUT_PACKET:-${CJGUI_STAGE793_PREVIEW_COMPONENT_API_COMMIT_DECISION_STATE_STORE_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage793-stage796/stage793/stage793-preview-component-api-commit-decision-state-store-bridge-suite.packet}}"
STAGE793_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage793_preview_component_api_commit_decision_state_store_bridge_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage794_preview_component_api_state_store_dry_run_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage794-preview-component-api-state-store-dry-run-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage794 preview component api state-store dry-run executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE793_SUITE_PACKET" ]] || ! grep -F "stage793_preview_component_api_commit_decision_state_store_bridge_suite_passed=true" "$STAGE793_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE793_TMPDIR="$TMP_DIR/stage793" zsh "$STAGE793_SUITE_SCRIPT" >/dev/null
  STAGE793_SUITE_PACKET="$TMP_DIR/stage793/stage793-preview-component-api-commit-decision-state-store-bridge-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage793_preview_component_api_commit_decision_state_store_bridge_consumed=true" \
  "component_state_store_dry_run_executor_materialized=true" \
  "state_store_mutation_preflight_ledger_materialized=true" \
  "rollback_slot_snapshot_materialized=true" \
  "text_edit_mutation_ledger_materialized=true" \
  "focus_handoff_mutation_ledger_materialized=true" \
  "style_token_mutation_ledger_materialized=true" \
  "dry_run_executor_bound_to_stage793_state_store_bridge=true" \
  "state_store_dry_run_non_committing=true" \
  "stage795_preview_component_api_state_store_inspection_surface_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage793_preview_component_api_commit_decision_state_store_bridge_suite_passed=true" \
  "commit_decision_state_store_bridge_materialized=true" \
  "stage794_preview_component_api_state_store_dry_run_executor_prepared=true"; do
  require_file_fact "$STAGE793_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage794_preview_component_api_state_store_dry_run_executor.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage794 preview component api state-store dry-run executor suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage794 preview component api state-store dry-run executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage794_preview_component_api_state_store_dry_run_executor_suite_version=1"
  echo "stage793_preview_component_api_commit_decision_state_store_bridge_suite_packet=$STAGE793_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage794_public_foreign_scan_passed=true"
  echo "stage794_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage795_preview_component_api_state_store_inspection_surface_after_stage794"
  echo "stage794_preview_component_api_state_store_dry_run_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage794 preview component api state-store dry-run executor suite: route_classification=component_state_store_dry_run_executor"
echo "cjgui stage794 preview component api state-store dry-run executor suite: suite_packet_path=$SUITE_PACKET"
