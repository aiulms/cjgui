#!/usr/bin/env zsh
#
# Focused suite for stage878. It consumes stage877 and records the acceptance
# decision reducer / receipt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE878_TMPDIR:-/private/tmp/cjgui-stage877-stage880/stage878}"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage878-owner-local-commit-acceptance-decision-suite.packet"
STAGE877_SUITE_PACKET="${CJGUI_STAGE878_INPUT_PACKET:-${CJGUI_STAGE877_OWNER_LOCAL_COMMIT_ACCEPTANCE_GATE_SUITE_PACKET:-/private/tmp/cjgui-stage877-stage880/stage877/stage877-owner-local-commit-acceptance-gate-suite.packet}}"
STAGE877_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage878_owner_local_commit_acceptance_decision_owner.sh"
OWNER_LOG="$TMP_DIR/stage878-owner-local-commit-acceptance-decision-owner.log"

mkdir -p "$TMP_DIR"
: > "$PUBLIC_SCAN_LOG"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage878 owner-local commit acceptance decision suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE877_SUITE_PACKET" ]] || ! grep -F "stage877_owner_local_commit_acceptance_gate_suite_passed=true" "$STAGE877_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE877_TMPDIR="$TMP_DIR/stage877" zsh "$STAGE877_SUITE_SCRIPT" >/dev/null
  STAGE877_SUITE_PACKET="$TMP_DIR/stage877/stage877-owner-local-commit-acceptance-gate-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage877_owner_local_commit_acceptance_gate_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage878_owner_local_commit_acceptance_decision_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage878_owner_local_commit_acceptance_decision_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage877_owner_local_commit_acceptance_gate_suite_passed=true" \
  "owner_local_commit_acceptance_policy_gate_materialized=true" \
  "owner_local_commit_acceptance_gate_bound_to_commit_receipt=true" \
  "stage878_owner_local_commit_acceptance_decision_prepared=true"; do
  require_file_fact "$STAGE877_SUITE_PACKET" "$fact"
done

for fact in \
  "stage877_owner_local_commit_acceptance_gate_consumed=true" \
  "owner_local_commit_acceptance_decision_reducer_materialized=true" \
  "owner_local_commit_acceptance_decision_ledger_materialized=true" \
  "owner_local_commit_acceptance_receipt_materialized=true" \
  "owner_local_commit_acceptance_rollback_binding_materialized=true" \
  "owner_local_commit_acceptance_receipt_not_published=true" \
  "owner_local_commit_accept_reject_request_changes_classified=true" \
  "stage879_owner_local_commit_acceptance_demo_surface_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for src in \
  "$ROOT_DIR/src/runtime_renderer_stage877_owner_local_commit_acceptance_gate.cj" \
  "$ROOT_DIR/src/runtime_renderer_stage878_owner_local_commit_acceptance_decision.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage878 owner-local commit acceptance decision suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage878 owner-local commit acceptance decision suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage878 owner-local commit acceptance decision suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalQueueSubmitShellReady"
if grep -E 'runtime_renderer_stage87(7|8).*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage878 owner-local commit acceptance decision suite: unexpected stage877-878 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage878 owner-local commit acceptance decision suite: protected production bridge/state path modified" >&2
  exit 14
fi

{
  echo "stage878_owner_local_commit_acceptance_decision_suite_version=1"
  echo "stage877_suite_packet=$STAGE877_SUITE_PACKET"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "stage877_stage878_public_declaration_scan_passed=true"
  echo "stage877_stage878_forbidden_native_render_token_scan_passed=true"
  echo "stage878_protected_path_scan_passed=true"
  echo "next_route=stage879_owner_local_commit_acceptance_demo_surface_after_stage878"
  echo "stage878_owner_local_commit_acceptance_decision_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage878 owner-local commit acceptance decision suite: route_classification=owner_local_commit_acceptance_decision"
echo "cjgui stage878 owner-local commit acceptance decision suite: suite_packet_path=$SUITE_PACKET"
