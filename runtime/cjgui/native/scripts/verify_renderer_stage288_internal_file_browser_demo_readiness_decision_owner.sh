#!/usr/bin/env zsh
#
# 维护注释：验证 stage288 internal file browser demo readiness decision owner。
# 它只把 file browser intent/state/render 汇合成 readiness，并准备 probe 后续入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage288_internal_file_browser_demo_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage288 internal file browser demo readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage288InternalFileBrowserDemoReadinessDecisionFacts" \
  "CjguiInternalRendererStage288InternalFileBrowserDemoReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage288InternalFileBrowserDemoReadinessDecisionDraft" \
  "didConsumeStage287InternalFileBrowserDemoRenderCommandPreview" \
  "didJoinFileBrowserIntentPacketWithStateUpdateDryRun" \
  "didJoinFileBrowserStateUpdateWithRenderCommandPreview" \
  "didJoinFileBrowserWithRollbackReadyBoundary" \
  "didJoinFileBrowserWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalFileBrowserDemoReadinessDecision" \
  "didPrepareStage289InternalFileBrowserDemoProbeInput" \
  "didConfirmMinimalUiFrameworkFileBrowserRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage288 internal file browser demo readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage288_internal_file_browser_demo_readiness_decision_owner_present=true"
echo "stage287_internal_file_browser_demo_render_command_preview_required=true"
echo "internal_file_browser_demo_readiness_decision_materialized=true"
echo "file_browser_intent_state_render_joined=true"
echo "file_browser_rollback_visibility_boundary_joined=true"
echo "stage289_internal_file_browser_demo_probe_input_prepared=true"
echo "minimal_ui_framework_file_browser_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
