#!/usr/bin/env zsh
#
# Focused suite for stage802. It consumes stage801 and records non-dispatching
# reviewer decision options for the semantic diff/explain packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE802_TMPDIR:-/private/tmp/cjgui-stage801-stage804/stage802}"
SUITE_PACKET="$TMP_DIR/stage802-preview-component-api-state-store-commit-review-decision-loop-suite.packet"
STAGE801_SUITE_PACKET="${CJGUI_STAGE802_INPUT_PACKET:-${CJGUI_STAGE801_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_DIFF_EXPLAIN_SUITE_PACKET:-/private/tmp/cjgui-stage801-stage804/stage801/stage801-preview-component-api-state-store-commit-diff-explain-suite.packet}}"
STAGE801_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage801_preview_component_api_state_store_commit_diff_explain_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage802_preview_component_api_state_store_commit_review_decision_loop_owner.sh"
OWNER_LOG="$TMP_DIR/stage802-preview-component-api-state-store-commit-review-decision-loop-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage802 preview component api state-store commit review decision loop suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE801_SUITE_PACKET" ]] || ! grep -F "stage801_preview_component_api_state_store_commit_diff_explain_suite_passed=true" "$STAGE801_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE801_TMPDIR="$TMP_DIR/stage801" zsh "$STAGE801_SUITE_SCRIPT" >/dev/null
  STAGE801_SUITE_PACKET="$TMP_DIR/stage801/stage801-preview-component-api-state-store-commit-diff-explain-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage801_preview_component_api_state_store_commit_diff_explain_consumed=true" \
  "reviewer_decision_options_materialized=true" \
  "reject_reason_taxonomy_materialized=true" \
  "request_changes_patch_hints_materialized=true" \
  "acceptance_hold_receipt_materialized=true" \
  "semantic_diff_acknowledge_route_materialized=true" \
  "reviewer_decision_loop_non_dispatching=true" \
  "stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_prepared=true" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage801_preview_component_api_state_store_commit_diff_explain_suite_passed=true" \
  "commit_admission_semantic_diff_model_materialized=true" \
  "stage802_preview_component_api_state_store_commit_review_decision_loop_prepared=true"; do
  require_file_fact "$STAGE801_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage802_preview_component_api_state_store_commit_review_decision_loop.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage802 preview component api state-store commit review decision loop suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage802 preview component api state-store commit review decision loop suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage802_preview_component_api_state_store_commit_review_decision_loop_suite_version=1"
  echo "stage801_preview_component_api_state_store_commit_diff_explain_suite_packet=$STAGE801_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage802_public_foreign_scan_passed=true"
  echo "stage802_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage803_preview_component_api_state_store_commit_diff_explain_demo_host_surface_after_stage802"
  echo "stage802_preview_component_api_state_store_commit_review_decision_loop_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage802 preview component api state-store commit review decision loop suite: route_classification=state_store_commit_review_decision_loop"
echo "cjgui stage802 preview component api state-store commit review decision loop suite: suite_packet_path=$SUITE_PACKET"
