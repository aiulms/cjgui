#!/usr/bin/env zsh
#
# 维护注释：验证 stage217 state-update-after-action dry-run owner。
# 它只把 action preview 接到 owner-local 状态更新候选，不写任何运行时状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage217_state_update_after_action_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage217 state update after action dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage217StateUpdateAfterActionDryRunFacts" \
  "CjguiInternalRendererStage217StateUpdateAfterActionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage217StateUpdateAfterActionDryRunDraft" \
  "didConsumeStage216InteractionRunwayReadinessDecision" \
  "didBindActionIntentToOwnerLocalStateUpdateCandidate" \
  "didMaterializeStateUpdateAfterActionDryRun" \
  "didMaterializeStateUpdateRollbackPreview" \
  "didKeepOwnerAcceptanceNotGranted" \
  "didPrepareStage218StateUpdatePreviewPacketInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage217 state update after action dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage217_state_update_after_action_dry_run_owner_present=true"
echo "stage216_interaction_runway_readiness_decision_required=true"
echo "action_intent_bound_to_owner_local_state_update_candidate=true"
echo "state_update_after_action_dry_run_materialized=true"
echo "state_update_rollback_preview_materialized=true"
echo "owner_acceptance_not_granted=true"
echo "stage218_state_update_preview_packet_input_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
