#!/usr/bin/env zsh
#
# Focused suite for stage798. It consumes stage797 and records owner review
# checkpoint evidence for the state-store commit admission preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE798_TMPDIR:-/private/tmp/cjgui-stage797-stage800/stage798}"
SUITE_PACKET="$TMP_DIR/stage798-preview-component-api-state-store-commit-review-checkpoint-suite.packet"
STAGE797_SUITE_PACKET="${CJGUI_STAGE798_INPUT_PACKET:-${CJGUI_STAGE797_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_ADMISSION_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage797-stage800/stage797/stage797-preview-component-api-state-store-commit-admission-preview-suite.packet}}"
STAGE797_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage797_preview_component_api_state_store_commit_admission_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage798_preview_component_api_state_store_commit_review_checkpoint_owner.sh"
OWNER_LOG="$TMP_DIR/stage798-preview-component-api-state-store-commit-review-checkpoint-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage798 preview component api state-store commit review checkpoint suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE797_SUITE_PACKET" ]] || ! grep -F "stage797_preview_component_api_state_store_commit_admission_preview_suite_passed=true" "$STAGE797_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE797_TMPDIR="$TMP_DIR/stage797" zsh "$STAGE797_SUITE_SCRIPT" >/dev/null
  STAGE797_SUITE_PACKET="$TMP_DIR/stage797/stage797-preview-component-api-state-store-commit-admission-preview-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage797_preview_component_api_state_store_commit_admission_preview_consumed=true" \
  "owner_commit_review_checkpoint_materialized=true" \
  "rollback_checkpoint_selection_materialized=true" \
  "compatibility_decision_receipt_materialized=true" \
  "deprecation_rollback_note_materialized=true" \
  "explainable_accept_reject_request_changes_receipt_materialized=true" \
  "commit_admission_checkpoint_non_committing=true" \
  "stage799_preview_component_api_state_store_commit_demo_host_preview_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage797_preview_component_api_state_store_commit_admission_preview_suite_passed=true" \
  "state_store_commit_admission_preview_gate_materialized=true" \
  "stage798_preview_component_api_state_store_commit_review_checkpoint_prepared=true"; do
  require_file_fact "$STAGE797_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage798_preview_component_api_state_store_commit_review_checkpoint.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage798 preview component api state-store commit review checkpoint suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage798 preview component api state-store commit review checkpoint suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage798_preview_component_api_state_store_commit_review_checkpoint_suite_version=1"
  echo "stage797_preview_component_api_state_store_commit_admission_preview_suite_packet=$STAGE797_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage798_public_foreign_scan_passed=true"
  echo "stage798_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage799_preview_component_api_state_store_commit_demo_host_preview_after_stage798"
  echo "stage798_preview_component_api_state_store_commit_review_checkpoint_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage798 preview component api state-store commit review checkpoint suite: route_classification=state_store_commit_review_checkpoint"
echo "cjgui stage798 preview component api state-store commit review checkpoint suite: suite_packet_path=$SUITE_PACKET"
