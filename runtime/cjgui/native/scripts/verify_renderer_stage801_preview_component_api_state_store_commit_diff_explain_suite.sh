#!/usr/bin/env zsh
#
# Focused suite for stage801. It consumes stage800 and records the semantic
# diff/explain packet for state-store commit admission previews.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE801_TMPDIR:-/private/tmp/cjgui-stage801-stage804/stage801}"
SUITE_PACKET="$TMP_DIR/stage801-preview-component-api-state-store-commit-diff-explain-suite.packet"
STAGE800_SUITE_PACKET="${CJGUI_STAGE801_INPUT_PACKET:-${CJGUI_STAGE800_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_ADMISSION_RUNTIME_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage797-stage800/stage800/stage800-preview-component-api-state-store-commit-admission-runtime-executor-suite.packet}}"
STAGE800_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage801_preview_component_api_state_store_commit_diff_explain_owner.sh"
OWNER_LOG="$TMP_DIR/stage801-preview-component-api-state-store-commit-diff-explain-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage801 preview component api state-store commit diff explain suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE800_SUITE_PACKET" ]] || ! grep -F "stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite_passed=true" "$STAGE800_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE800_TMPDIR="$TMP_DIR/stage800" zsh "$STAGE800_SUITE_SCRIPT" >/dev/null
  STAGE800_SUITE_PACKET="$TMP_DIR/stage800/stage800-preview-component-api-state-store-commit-admission-runtime-executor-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage800_preview_component_api_state_store_commit_admission_runtime_executor_consumed=true" \
  "commit_admission_semantic_diff_model_materialized=true" \
  "mutation_explain_rows_materialized=true" \
  "affected_component_map_materialized=true" \
  "rollback_diff_summary_materialized=true" \
  "compatibility_explain_lane_materialized=true" \
  "diff_explain_bound_to_stage800_runtime_executor=true" \
  "commit_diff_explain_non_committing=true" \
  "stage802_preview_component_api_state_store_commit_review_decision_loop_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite_passed=true" \
  "shared_state_store_commit_admission_runtime_executor_materialized=true" \
  "stage801_preview_component_api_state_store_commit_admission_diff_explain_prepared=true"; do
  require_file_fact "$STAGE800_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage801_preview_component_api_state_store_commit_diff_explain.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage801 preview component api state-store commit diff explain suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage801 preview component api state-store commit diff explain suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage801_preview_component_api_state_store_commit_diff_explain_suite_version=1"
  echo "stage800_preview_component_api_state_store_commit_admission_runtime_executor_suite_packet=$STAGE800_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage801_public_foreign_scan_passed=true"
  echo "stage801_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage802_preview_component_api_state_store_commit_review_decision_loop_after_stage801"
  echo "stage801_preview_component_api_state_store_commit_diff_explain_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage801 preview component api state-store commit diff explain suite: route_classification=state_store_commit_diff_explain"
echo "cjgui stage801 preview component api state-store commit diff explain suite: suite_packet_path=$SUITE_PACKET"
