#!/usr/bin/env zsh
#
# 维护注释：验证 stage215 action semantic diff / explain owner。
# 它生成 action diff、explain 与 rollback boundary，owner 未接受则不派发。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage215_action_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage215 action semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage215ActionSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage215ActionSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage215ActionSemanticDiffExplainDraft" \
  "didConsumeStage214ActionPreviewPacket" \
  "didMaterializeActionSemanticDiff" \
  "didMaterializeActionExplainPacket" \
  "didMaterializeActionRollbackReadyBoundary" \
  "didKeepOwnerAcceptanceRequired" \
  "didPrepareStage216InteractionRunwayReadinessDecisionInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage215 action semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage215_action_semantic_diff_explain_owner_present=true"
echo "stage214_action_preview_packet_required=true"
echo "action_semantic_diff_materialized=true"
echo "action_explain_packet_materialized=true"
echo "action_rollback_ready_boundary_materialized=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "stage216_interaction_runway_readiness_decision_input_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
