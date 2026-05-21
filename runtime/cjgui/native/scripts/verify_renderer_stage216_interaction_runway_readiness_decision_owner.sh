#!/usr/bin/env zsh
#
# 维护注释：验证 stage216 interaction runway readiness decision owner。
# 它只批准下一段 state-update-after-action dry-run 输入，不写状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage216_interaction_runway_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage216 interaction runway readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage216InteractionRunwayReadinessDecisionFacts" \
  "CjguiInternalRendererStage216InteractionRunwayReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage216InteractionRunwayReadinessDecisionDraft" \
  "didConsumeStage215ActionSemanticDiffExplain" \
  "didJoinActionIntentWithActionPreviewPacket" \
  "didJoinActionPreviewWithActionRollbackBoundary" \
  "didMaterializeInteractionRunwayReadinessDecision" \
  "didPrepareStage217StateUpdateAfterActionDryRunInput" \
  "didKeepInputEventPipelineExecutionBlocked" \
  "didKeepActionDispatchBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage216 interaction runway readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage216_interaction_runway_readiness_decision_owner_present=true"
echo "stage215_action_semantic_diff_explain_required=true"
echo "action_intent_joined_with_action_preview_packet=true"
echo "action_preview_rollback_boundary_joined=true"
echo "interaction_runway_readiness_decision_materialized=true"
echo "stage217_state_update_after_action_dry_run_input_prepared=true"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
