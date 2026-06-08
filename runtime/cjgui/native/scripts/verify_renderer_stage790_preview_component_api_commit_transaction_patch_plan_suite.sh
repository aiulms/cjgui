#!/usr/bin/env zsh
#
# Focused suite for stage790. It consumes stage789 and records the owner-local
# transaction patch plan for preview component API commit decisions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE790_TMPDIR:-/private/tmp/cjgui-stage789-stage792/stage790}"
SUITE_PACKET="$TMP_DIR/stage790-preview-component-api-commit-transaction-patch-plan-suite.packet"
STAGE789_SUITE_PACKET="${CJGUI_STAGE790_INPUT_PACKET:-${CJGUI_STAGE789_PREVIEW_COMPONENT_API_COMMIT_ADMISSION_DECISION_SUITE_PACKET:-/private/tmp/cjgui-stage789-stage792/stage789/stage789-preview-component-api-commit-admission-decision-suite.packet}}"
STAGE789_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage789_preview_component_api_commit_admission_decision_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage790_preview_component_api_commit_transaction_patch_plan_owner.sh"
OWNER_LOG="$TMP_DIR/stage790-preview-component-api-commit-transaction-patch-plan-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage790 preview component api commit transaction patch plan suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE789_SUITE_PACKET" ]] || ! grep -F "stage789_preview_component_api_commit_admission_decision_suite_passed=true" "$STAGE789_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE789_TMPDIR="$TMP_DIR/stage789" zsh "$STAGE789_SUITE_SCRIPT" >/dev/null
  STAGE789_SUITE_PACKET="$TMP_DIR/stage789/stage789-preview-component-api-commit-admission-decision-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage789_preview_component_api_commit_admission_decision_consumed=true" \
  "owner_local_transaction_patch_plan_materialized=true" \
  "rollback_snapshot_handle_materialized=true" \
  "conflict_version_check_materialized=true" \
  "focus_handoff_patch_placeholder_materialized=true" \
  "text_edit_patch_placeholder_materialized=true" \
  "style_delta_patch_placeholder_materialized=true" \
  "accepted_decision_patch_branch_materialized=true" \
  "rejected_decision_rollback_branch_materialized=true" \
  "transaction_patch_plan_bound_to_stage789_decision_resolver=true" \
  "commit_transaction_patch_plan_non_committing=true" \
  "stage791_preview_component_api_commit_transaction_demo_host_surface_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage789_preview_component_api_commit_admission_decision_suite_passed=true" \
  "preview_component_api_commit_admission_decision_resolver_materialized=true" \
  "stage790_preview_component_api_commit_transaction_patch_plan_prepared=true"; do
  require_file_fact "$STAGE789_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage790_preview_component_api_commit_transaction_patch_plan.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage790 preview component api commit transaction patch plan suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage790 preview component api commit transaction patch plan suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage790_preview_component_api_commit_transaction_patch_plan_suite_version=1"
  echo "stage789_preview_component_api_commit_admission_decision_suite_packet=$STAGE789_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage790_public_foreign_scan_passed=true"
  echo "stage790_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage791_preview_component_api_commit_transaction_demo_host_surface_after_stage790"
  echo "stage790_preview_component_api_commit_transaction_patch_plan_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage790 preview component api commit transaction patch plan suite: route_classification=owner_local_transaction_patch_plan"
echo "cjgui stage790 preview component api commit transaction patch plan suite: suite_packet_path=$SUITE_PACKET"
