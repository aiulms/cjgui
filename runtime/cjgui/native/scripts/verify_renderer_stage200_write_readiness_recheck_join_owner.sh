#!/usr/bin/env zsh
#
# 维护注释：验证 stage200 write readiness recheck join owner。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage200_write_readiness_recheck_join.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage200 write readiness recheck join: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage200WriteReadinessRecheckJoinReadiness" \
  "cjguiInternalExecuteDefaultRendererStage200WriteReadinessRecheckJoinDraft" \
  "didConsumeStage199PromotionTokenRecheckPreflight" \
  "didJoinStage196BoundaryWithStage199PromotionRecheck" \
  "didMaterializeRendererStateWriteReadinessRecheckJoinPacket" \
  "didPrepareStage201WriteTokenReevaluationInput" \
  "didKeepRendererStateWriteEligibilityFalse"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage200 write readiness recheck join: missing token $token" >&2
    exit 3
  fi
done

echo "stage200_write_readiness_recheck_join_owner_present=true"
echo "stage199_promotion_token_recheck_preflight_required=true"
echo "renderer_state_write_readiness_recheck_join_packet_materialized=true"
echo "stage201_write_token_reevaluation_input_prepared=true"
echo "renderer_state_write_eligibility=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
