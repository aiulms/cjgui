#!/usr/bin/env zsh
#
# Focused suite for stage793. It consumes stage792 and records the non-committing
# commit decision to state-store bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE793_TMPDIR:-/private/tmp/cjgui-stage793-stage796/stage793}"
SUITE_PACKET="$TMP_DIR/stage793-preview-component-api-commit-decision-state-store-bridge-suite.packet"
STAGE792_SUITE_PACKET="${CJGUI_STAGE793_INPUT_PACKET:-${CJGUI_STAGE792_PREVIEW_COMPONENT_API_COMMIT_DECISION_TRANSACTION_RUNTIME_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage789-stage792/stage792/stage792-preview-component-api-commit-decision-transaction-runtime-executor-suite.packet}}"
STAGE792_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage792_preview_component_api_commit_decision_transaction_runtime_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage793_preview_component_api_commit_decision_state_store_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage793-preview-component-api-commit-decision-state-store-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage793 preview component api commit decision state-store bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE792_SUITE_PACKET" ]] || ! grep -F "stage792_preview_component_api_commit_decision_transaction_runtime_executor_suite_passed=true" "$STAGE792_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE792_TMPDIR="$TMP_DIR/stage792" zsh "$STAGE792_SUITE_SCRIPT" >/dev/null
  STAGE792_SUITE_PACKET="$TMP_DIR/stage792/stage792-preview-component-api-commit-decision-transaction-runtime-executor-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage792_preview_component_api_commit_decision_transaction_runtime_executor_consumed=true" \
  "commit_decision_state_store_bridge_materialized=true" \
  "owner_local_write_set_route_classifier_materialized=true" \
  "accepted_decision_write_set_candidate_materialized=true" \
  "rejected_decision_noop_write_set_materialized=true" \
  "rollback_only_state_store_route_materialized=true" \
  "request_changes_state_store_route_materialized=true" \
  "state_store_bridge_bound_to_stage792_transaction_executor=true" \
  "commit_decision_state_store_bridge_non_committing=true" \
  "stage794_preview_component_api_state_store_dry_run_executor_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage792_preview_component_api_commit_decision_transaction_runtime_executor_suite_passed=true" \
  "stage793_preview_component_api_commit_decision_state_store_bridge_prepared=true" \
  "shared_commit_decision_transaction_runtime_executor_materialized=true" \
  "commit_decision_transaction_execution_receipt_contract_materialized=true"; do
  require_file_fact "$STAGE792_SUITE_PACKET" "$fact"
done

OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage793_preview_component_api_commit_decision_state_store_bridge.cj"
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
  echo "cjgui stage793 preview component api commit decision state-store bridge suite: unexpected public or foreign declaration in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage793 preview component api commit decision state-store bridge suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

{
  echo "stage793_preview_component_api_commit_decision_state_store_bridge_suite_version=1"
  echo "stage792_preview_component_api_commit_decision_transaction_runtime_executor_suite_packet=$STAGE792_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage793_public_foreign_scan_passed=true"
  echo "stage793_forbidden_native_render_token_scan_passed=true"
  echo "next_route=stage794_preview_component_api_state_store_dry_run_executor_after_stage793"
  echo "stage793_preview_component_api_commit_decision_state_store_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage793 preview component api commit decision state-store bridge suite: route_classification=commit_decision_state_store_bridge"
echo "cjgui stage793 preview component api commit decision state-store bridge suite: suite_packet_path=$SUITE_PACKET"
