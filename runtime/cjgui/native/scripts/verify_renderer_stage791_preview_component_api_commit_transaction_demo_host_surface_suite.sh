#!/usr/bin/env zsh
#
# Focused suite for stage791. It consumes stage790 and records the demo-host
# inspection/result surface for commit transaction previews.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE791_TMPDIR:-/private/tmp/cjgui-stage789-stage792/stage791}"
SUITE_PACKET="$TMP_DIR/stage791-preview-component-api-commit-transaction-demo-host-surface-suite.packet"
STAGE790_SUITE_PACKET="${CJGUI_STAGE791_INPUT_PACKET:-${CJGUI_STAGE790_PREVIEW_COMPONENT_API_COMMIT_TRANSACTION_PATCH_PLAN_SUITE_PACKET:-/private/tmp/cjgui-stage789-stage792/stage790/stage790-preview-component-api-commit-transaction-patch-plan-suite.packet}}"
STAGE790_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage790_preview_component_api_commit_transaction_patch_plan_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage791_preview_component_api_commit_transaction_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage791-preview-component-api-commit-transaction-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage791 preview component api commit transaction demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE790_SUITE_PACKET" ]] || ! grep -F "stage790_preview_component_api_commit_transaction_patch_plan_suite_passed=true" "$STAGE790_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE790_TMPDIR="$TMP_DIR/stage790" zsh "$STAGE790_SUITE_SCRIPT" >/dev/null
  STAGE790_SUITE_PACKET="$TMP_DIR/stage790/stage790-preview-component-api-commit-transaction-patch-plan-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage790_preview_component_api_commit_transaction_patch_plan_consumed=true" \
  "commit_transaction_host_inspection_receipt_materialized=true" \
  "commit_transaction_result_surface_refresh_materialized=true" \
  "commit_transaction_rollback_preview_receipt_materialized=true" \
  "commit_transaction_semantic_diff_explain_materialized=true" \
  "todo_commit_transaction_demo_host_surface_materialized=true" \
  "settings_commit_transaction_demo_host_surface_materialized=true" \
  "ai_generated_settings_commit_transaction_demo_host_surface_materialized=true" \
  "chat_composer_commit_transaction_demo_host_surface_materialized=true" \
  "demo_host_surface_bound_to_stage790_transaction_patch_plan=true" \
  "commit_transaction_demo_host_surface_non_committing=true" \
  "stage792_preview_component_api_commit_decision_transaction_runtime_executor_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage790_preview_component_api_commit_transaction_patch_plan_suite_passed=true" \
  "owner_local_transaction_patch_plan_materialized=true" \
  "stage791_preview_component_api_commit_transaction_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE790_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage791_preview_component_api_commit_transaction_demo_host_surface.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage791 preview component api commit transaction demo-host surface suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage791 preview component api commit transaction demo-host surface suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage791_preview_component_api_commit_transaction_demo_host_surface_suite_version=1"
  echo "stage790_preview_component_api_commit_transaction_patch_plan_suite_packet=$STAGE790_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage791_public_foreign_scan_passed=true"
  echo "stage791_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage792_preview_component_api_commit_decision_transaction_runtime_executor_after_stage791"
  echo "stage791_preview_component_api_commit_transaction_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage791 preview component api commit transaction demo-host surface suite: route_classification=commit_transaction_demo_host_surface"
echo "cjgui stage791 preview component api commit transaction demo-host surface suite: suite_packet_path=$SUITE_PACKET"
