#!/usr/bin/env zsh
#
# Focused suite for stage797. It consumes stage796 and records the non-committing
# state-store commit admission preview gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE797_TMPDIR:-/private/tmp/cjgui-stage797-stage800/stage797}"
SUITE_PACKET="$TMP_DIR/stage797-preview-component-api-state-store-commit-admission-preview-suite.packet"
STAGE796_SUITE_PACKET="${CJGUI_STAGE797_INPUT_PACKET:-${CJGUI_STAGE796_PREVIEW_COMPONENT_API_STATE_STORE_BRIDGE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage793-stage796/stage796/stage796-preview-component-api-state-store-bridge-runtime-manager-suite.packet}}"
STAGE796_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage796_preview_component_api_state_store_bridge_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage797_preview_component_api_state_store_commit_admission_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage797-preview-component-api-state-store-commit-admission-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage797 preview component api state-store commit admission preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE796_SUITE_PACKET" ]] || ! grep -F "stage796_preview_component_api_state_store_bridge_runtime_manager_suite_passed=true" "$STAGE796_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE796_TMPDIR="$TMP_DIR/stage796" zsh "$STAGE796_SUITE_SCRIPT" >/dev/null
  STAGE796_SUITE_PACKET="$TMP_DIR/stage796/stage796-preview-component-api-state-store-bridge-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage796_preview_component_api_state_store_bridge_runtime_manager_consumed=true" \
  "state_store_commit_admission_preview_gate_materialized=true" \
  "owner_local_commit_admission_policy_matrix_materialized=true" \
  "text_mutation_admission_route_materialized=true" \
  "focus_mutation_admission_route_materialized=true" \
  "style_mutation_admission_route_materialized=true" \
  "layout_mutation_admission_route_materialized=true" \
  "state_store_commit_admission_preview_non_committing=true" \
  "stage798_preview_component_api_state_store_commit_review_checkpoint_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage796_preview_component_api_state_store_bridge_runtime_manager_suite_passed=true" \
  "shared_component_state_store_bridge_runtime_manager_materialized=true" \
  "stage797_preview_component_api_state_store_commit_admission_preview_prepared=true"; do
  require_file_fact "$STAGE796_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage797_preview_component_api_state_store_commit_admission_preview.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage797 preview component api state-store commit admission preview suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage797 preview component api state-store commit admission preview suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage797_preview_component_api_state_store_commit_admission_preview_suite_version=1"
  echo "stage796_preview_component_api_state_store_bridge_runtime_manager_suite_packet=$STAGE796_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage797_public_foreign_scan_passed=true"
  echo "stage797_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage798_preview_component_api_state_store_commit_review_checkpoint_after_stage797"
  echo "stage797_preview_component_api_state_store_commit_admission_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage797 preview component api state-store commit admission preview suite: route_classification=state_store_commit_admission_preview"
echo "cjgui stage797 preview component api state-store commit admission preview suite: suite_packet_path=$SUITE_PACKET"
