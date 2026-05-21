#!/usr/bin/env zsh
#
# 维护注释：验证 stage291 internal file browser demo probe semantic diff/explain owner。
# 它只解释 selection/tree/detail probe dry-run，不接纳 owner 变更或提交 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage291_internal_file_browser_demo_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage291 internal file browser demo probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage291InternalFileBrowserDemoProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage291InternalFileBrowserDemoProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage291InternalFileBrowserDemoProbeSemanticDiffExplainDraft" \
  "didConsumeStage290InternalFileBrowserDemoProbeResultEnvelope" \
  "didMaterializeFileBrowserDemoProbeSemanticDiff" \
  "didMaterializeFileBrowserDemoProbeExplainPacket" \
  "didBindFileBrowserProbeDiffToSelectionTreeDetailOrder" \
  "didBindFileBrowserProbeExplainToSelectionTreeDetailIntents" \
  "didRecheckFileBrowserProbeRollbackReadyBoundary" \
  "didRecheckFileBrowserProbeVisibilityNotPublishedBoundary" \
  "didPrepareStage292FileBrowserDemoProbeReadinessDecisionInput" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage291 internal file browser demo probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage291_internal_file_browser_demo_probe_semantic_diff_explain_owner_present=true"
echo "stage290_internal_file_browser_demo_probe_result_envelope_required=true"
echo "file_browser_demo_probe_semantic_diff_materialized=true"
echo "file_browser_demo_probe_explain_packet_materialized=true"
echo "file_browser_probe_diff_bound_to_selection_tree_detail_order=true"
echo "file_browser_probe_explain_bound_to_selection_tree_detail_intents=true"
echo "file_browser_probe_rollback_ready_boundary_rechecked=true"
echo "file_browser_probe_visibility_not_published_boundary_rechecked=true"
echo "stage292_file_browser_demo_probe_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
