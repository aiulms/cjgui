#!/usr/bin/env zsh
#
# Focused suite for stage799. It consumes stage798 and records demo-host
# inspection/result preview surfaces across five demo classes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE799_TMPDIR:-/private/tmp/cjgui-stage797-stage800/stage799}"
SUITE_PACKET="$TMP_DIR/stage799-preview-component-api-state-store-commit-demo-host-preview-suite.packet"
STAGE798_SUITE_PACKET="${CJGUI_STAGE799_INPUT_PACKET:-${CJGUI_STAGE798_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_REVIEW_CHECKPOINT_SUITE_PACKET:-/private/tmp/cjgui-stage797-stage800/stage798/stage798-preview-component-api-state-store-commit-review-checkpoint-suite.packet}}"
STAGE798_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage798_preview_component_api_state_store_commit_review_checkpoint_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage799_preview_component_api_state_store_commit_demo_host_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage799-preview-component-api-state-store-commit-demo-host-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage799 preview component api state-store commit demo-host preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE798_SUITE_PACKET" ]] || ! grep -F "stage798_preview_component_api_state_store_commit_review_checkpoint_suite_passed=true" "$STAGE798_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE798_TMPDIR="$TMP_DIR/stage798" zsh "$STAGE798_SUITE_SCRIPT" >/dev/null
  STAGE798_SUITE_PACKET="$TMP_DIR/stage798/stage798-preview-component-api-state-store-commit-review-checkpoint-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage798_preview_component_api_state_store_commit_review_checkpoint_consumed=true" \
  "commit_admission_demo_host_preview_rows_materialized=true" \
  "commit_admission_result_surface_refresh_materialized=true" \
  "commit_admission_host_inspection_receipt_materialized=true" \
  "todo_commit_admission_preview_surface_materialized=true" \
  "settings_commit_admission_preview_surface_materialized=true" \
  "ai_generated_settings_commit_admission_preview_surface_materialized=true" \
  "chat_composer_commit_admission_preview_surface_materialized=true" \
  "file_browser_commit_admission_preview_surface_materialized=true" \
  "stage800_preview_component_api_state_store_commit_admission_runtime_executor_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage798_preview_component_api_state_store_commit_review_checkpoint_suite_passed=true" \
  "owner_commit_review_checkpoint_materialized=true" \
  "stage799_preview_component_api_state_store_commit_demo_host_preview_prepared=true"; do
  require_file_fact "$STAGE798_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage799_preview_component_api_state_store_commit_demo_host_preview.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage799 preview component api state-store commit demo-host preview suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage799 preview component api state-store commit demo-host preview suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage799_preview_component_api_state_store_commit_demo_host_preview_suite_version=1"
  echo "stage798_preview_component_api_state_store_commit_review_checkpoint_suite_packet=$STAGE798_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage799_public_foreign_scan_passed=true"
  echo "stage799_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage800_preview_component_api_state_store_commit_admission_runtime_executor_after_stage799"
  echo "stage799_preview_component_api_state_store_commit_demo_host_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage799 preview component api state-store commit demo-host preview suite: route_classification=state_store_commit_demo_host_preview"
echo "cjgui stage799 preview component api state-store commit demo-host preview suite: suite_packet_path=$SUITE_PACKET"
