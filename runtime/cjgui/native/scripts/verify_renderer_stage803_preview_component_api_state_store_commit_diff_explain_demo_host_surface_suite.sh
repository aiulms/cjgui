#!/usr/bin/env zsh
#
# Focused suite for stage803. It consumes stage802 and records demo-host
# diff/explain inspection/result surfaces across five demo classes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE803_TMPDIR:-/private/tmp/cjgui-stage801-stage804/stage803}"
SUITE_PACKET="$TMP_DIR/stage803-preview-component-api-state-store-commit-diff-explain-demo-host-surface-suite.packet"
STAGE802_SUITE_PACKET="${CJGUI_STAGE803_INPUT_PACKET:-${CJGUI_STAGE802_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_REVIEW_DECISION_LOOP_SUITE_PACKET:-/private/tmp/cjgui-stage801-stage804/stage802/stage802-preview-component-api-state-store-commit-review-decision-loop-suite.packet}}"
STAGE802_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage802_preview_component_api_state_store_commit_review_decision_loop_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage803-preview-component-api-state-store-commit-diff-explain-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE802_SUITE_PACKET" ]] || ! grep -F "stage802_preview_component_api_state_store_commit_review_decision_loop_suite_passed=true" "$STAGE802_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE802_TMPDIR="$TMP_DIR/stage802" zsh "$STAGE802_SUITE_SCRIPT" >/dev/null
  STAGE802_SUITE_PACKET="$TMP_DIR/stage802/stage802-preview-component-api-state-store-commit-review-decision-loop-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage802_preview_component_api_state_store_commit_review_decision_loop_consumed=true" \
  "diff_explain_host_inspection_rows_materialized=true" \
  "diff_explain_result_surface_refresh_materialized=true" \
  "mutation_explain_panel_materialized=true" \
  "todo_diff_explain_preview_surface_materialized=true" \
  "settings_diff_explain_preview_surface_materialized=true" \
  "ai_generated_settings_diff_explain_preview_surface_materialized=true" \
  "chat_composer_diff_explain_preview_surface_materialized=true" \
  "file_browser_diff_explain_preview_surface_materialized=true" \
  "stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage802_preview_component_api_state_store_commit_review_decision_loop_suite_passed=true" \
  "reviewer_decision_options_materialized=true" \
  "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE802_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_suite_version=1"
  echo "stage802_preview_component_api_state_store_commit_review_decision_loop_suite_packet=$STAGE802_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage803_public_foreign_scan_passed=true"
  echo "stage803_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage804_preview_component_api_state_store_commit_diff_explain_runtime_manager_after_stage803"
  echo "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface suite: route_classification=state_store_commit_diff_explain_demo_host_surface"
echo "cjgui stage803 preview component api state-store commit diff explain demo-host surface suite: suite_packet_path=$SUITE_PACKET"
