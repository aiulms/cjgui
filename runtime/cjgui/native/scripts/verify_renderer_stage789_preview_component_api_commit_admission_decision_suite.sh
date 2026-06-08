#!/usr/bin/env zsh
#
# Focused suite for stage789. It consumes stage788 and records the non-dispatching
# preview component API commit admission decision resolver.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE789_TMPDIR:-/private/tmp/cjgui-stage789-stage792/stage789}"
SUITE_PACKET="$TMP_DIR/stage789-preview-component-api-commit-admission-decision-suite.packet"
STAGE788_SUITE_PACKET="${CJGUI_STAGE789_INPUT_PACKET:-${CJGUI_STAGE788_PREVIEW_COMPONENT_API_COMMIT_INSPECTION_PUBLIC_PREVIEW_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage785-stage788/stage788/stage788-preview-component-api-commit-inspection-public-preview-runtime-manager-suite.packet}}"
STAGE788_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage789_preview_component_api_commit_admission_decision_owner.sh"
OWNER_LOG="$TMP_DIR/stage789-preview-component-api-commit-admission-decision-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage789 preview component api commit admission decision suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE788_SUITE_PACKET" ]] || ! grep -F "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_suite_passed=true" "$STAGE788_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE788_TMPDIR="$TMP_DIR/stage788" zsh "$STAGE788_SUITE_SCRIPT" >/dev/null
  STAGE788_SUITE_PACKET="$TMP_DIR/stage788/stage788-preview-component-api-commit-inspection-public-preview-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_consumed=true" \
  "public_preview_contract_runtime_manager_consumed=true" \
  "preview_component_api_commit_admission_decision_resolver_materialized=true" \
  "accepted_preview_commit_decision_route_materialized=true" \
  "rejected_preview_commit_decision_route_materialized=true" \
  "request_changes_commit_decision_route_materialized=true" \
  "rollback_only_commit_decision_route_materialized=true" \
  "owner_controlled_commit_decision_ledger_materialized=true" \
  "commit_admission_decision_non_dispatching=true" \
  "stage790_preview_component_api_commit_transaction_patch_plan_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_suite_passed=true" \
  "stage789_preview_component_api_commit_admission_decision_prepared=true" \
  "shared_public_preview_contract_runtime_manager_materialized=true" \
  "future_per_demo_public_preview_contract_template_need_reduced=true"; do
  require_file_fact "$STAGE788_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage789_preview_component_api_commit_admission_decision.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage789 preview component api commit admission decision suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage789 preview component api commit admission decision suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage789_preview_component_api_commit_admission_decision_suite_version=1"
  echo "stage788_preview_component_api_commit_inspection_public_preview_runtime_manager_suite_packet=$STAGE788_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage789_public_foreign_scan_passed=true"
  echo "stage789_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage790_preview_component_api_commit_transaction_patch_plan_after_stage789"
  echo "stage789_preview_component_api_commit_admission_decision_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage789 preview component api commit admission decision suite: route_classification=commit_admission_decision_resolver"
echo "cjgui stage789 preview component api commit admission decision suite: suite_packet_path=$SUITE_PACKET"
