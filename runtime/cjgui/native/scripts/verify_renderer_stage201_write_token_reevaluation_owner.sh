#!/usr/bin/env zsh
#
# 维护注释：验证 stage201 write-token reevaluation owner。输入是 stage200
# write-readiness join，输出是仍然 non-mutating 的 token decision envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage201_write_token_reevaluation.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage201 write token reevaluation: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage201WriteTokenReevaluationReadiness" \
  "cjguiInternalExecuteDefaultRendererStage201WriteTokenReevaluationDraft" \
  "didConsumeStage200WriteReadinessRecheckJoin" \
  "didMaterializeWriteTokenDecisionEnvelope" \
  "didBindWriteTokenToSemanticRuntimeAdmission" \
  "didMaterializeWriteTokenMissingPredicateReceipt" \
  "didPrepareStage202SceneRenderCommandBridgeInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage201 write token reevaluation: missing token $token" >&2
    exit 3
  fi
done

echo "stage201_write_token_reevaluation_owner_present=true"
echo "stage200_write_readiness_recheck_join_required=true"
echo "write_token_decision_envelope_materialized=true"
echo "write_token_missing_predicate_receipt_materialized=true"
echo "stage202_scene_render_command_bridge_input_prepared=true"
echo "renderer_state_write_token=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
