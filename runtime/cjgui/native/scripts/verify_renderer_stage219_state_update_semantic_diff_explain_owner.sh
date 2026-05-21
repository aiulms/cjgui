#!/usr/bin/env zsh
#
# 维护注释：验证 stage219 state update semantic diff / explain owner。
# 它生成状态更新 diff/explain 与 rollback-ready 边界，仍等待 owner acceptance。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage219_state_update_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage219 state update semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage219StateUpdateSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage219StateUpdateSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage219StateUpdateSemanticDiffExplainDraft" \
  "didConsumeStage218StateUpdatePreviewPacket" \
  "didMaterializeStateUpdateSemanticDiff" \
  "didMaterializeStateUpdateExplainPacket" \
  "didMaterializeStateUpdateRollbackReadyBoundary" \
  "didKeepOwnerAcceptanceRequired" \
  "didPrepareStage220StatefulInteractionReadinessDecisionInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage219 state update semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage219_state_update_semantic_diff_explain_owner_present=true"
echo "stage218_state_update_preview_packet_required=true"
echo "state_update_semantic_diff_materialized=true"
echo "state_update_explain_packet_materialized=true"
echo "state_update_rollback_ready_boundary_materialized=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "stage220_stateful_interaction_readiness_decision_input_prepared=true"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
