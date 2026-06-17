#!/usr/bin/env zsh
#
# Focused suite for stage877. It consumes stage876 and records the owner-local
# commit acceptance policy gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE877_TMPDIR:-/private/tmp/cjgui-stage877-stage880/stage877}"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage877-owner-local-commit-acceptance-gate-suite.packet"
STAGE876_SUITE_PACKET="${CJGUI_STAGE877_INPUT_PACKET:-${CJGUI_STAGE876_OWNER_LOCAL_STATE_STORE_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage873-stage876/stage876/stage876-owner-local-state-store-commit-runtime-manager-suite.packet}}"
STAGE876_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage876_owner_local_state_store_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_owner.sh"
OWNER_LOG="$TMP_DIR/stage877-owner-local-commit-acceptance-gate-owner.log"

mkdir -p "$TMP_DIR"
: > "$PUBLIC_SCAN_LOG"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage877 owner-local commit acceptance gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE876_SUITE_PACKET" ]] || ! grep -F "stage876_owner_local_state_store_commit_runtime_manager_suite_passed=true" "$STAGE876_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE876_TMPDIR="$TMP_DIR/stage876" zsh "$STAGE876_SUITE_SCRIPT" >/dev/null
  STAGE876_SUITE_PACKET="$TMP_DIR/stage876/stage876-owner-local-state-store-commit-runtime-manager-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage876_owner_local_state_store_commit_runtime_manager_suite_passed=true" \
  "shared_owner_local_state_store_commit_runtime_manager_materialized=true" \
  "common_owner_local_state_store_commit_executor_materialized=true" \
  "stage877_owner_acceptance_after_owner_local_state_store_commit_prepared=true"; do
  require_file_fact "$STAGE876_SUITE_PACKET" "$fact"
done

for fact in \
  "stage876_owner_local_commit_runtime_manager_consumed=true" \
  "owner_local_commit_acceptance_policy_gate_materialized=true" \
  "owner_local_commit_acceptance_request_envelope_materialized=true" \
  "owner_local_commit_review_scope_matrix_materialized=true" \
  "owner_local_commit_accept_reject_request_changes_routes_materialized=true" \
  "owner_local_commit_acceptance_gate_bound_to_commit_receipt=true" \
  "stage878_owner_local_commit_acceptance_decision_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "new_public_surface_added=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

SRC="$ROOT_DIR/src/runtime_renderer_stage877_owner_local_commit_acceptance_gate.cj"
if [[ ! -f "$SRC" ]]; then
  echo "cjgui stage877 owner-local commit acceptance gate suite: missing source $SRC" >&2
  exit 10
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage877 owner-local commit acceptance gate suite: unexpected public or foreign declaration in $SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage877 owner-local commit acceptance gate suite: forbidden native/render token found in $SRC" >&2
  exit 12
fi

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalQueueSubmitShellReady"
if grep -E 'runtime_renderer_stage877.*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage877 owner-local commit acceptance gate suite: unexpected stage877 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage877 owner-local commit acceptance gate suite: protected production bridge/state path modified" >&2
  exit 14
fi

{
  echo "stage877_owner_local_commit_acceptance_gate_suite_version=1"
  echo "stage876_suite_packet=$STAGE876_SUITE_PACKET"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "stage877_public_declaration_scan_passed=true"
  echo "stage877_forbidden_native_render_token_scan_passed=true"
  echo "stage877_protected_path_scan_passed=true"
  echo "next_route=stage878_owner_local_commit_acceptance_decision_after_stage877"
  echo "stage877_owner_local_commit_acceptance_gate_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage877 owner-local commit acceptance gate suite: route_classification=owner_local_commit_acceptance_gate"
echo "cjgui stage877 owner-local commit acceptance gate suite: suite_packet_path=$SUITE_PACKET"
