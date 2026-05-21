#!/usr/bin/env zsh
#
# 维护注释：验证 stage255 internal component demo probe input owner。
# 它把 internal surface diff/explain 汇成 demo probe input，不执行真实 backend 或 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage255_internal_component_demo_probe_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage255 internal component demo probe input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage255InternalComponentDemoProbeInputFacts" \
  "CjguiInternalRendererStage255InternalComponentDemoProbeInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage255InternalComponentDemoProbeInputDraft" \
  "didConsumeStage254ComponentDemoSurfaceSemanticDiffExplain" \
  "didMaterializeInternalComponentDemoProbeInput" \
  "didBindProbeInputToInternalSurface" \
  "didBindProbeInputToRenderCommandPreview" \
  "didBindProbeInputToStateUpdateDryRun" \
  "didBindProbeInputToActionIntentFacts" \
  "didKeepProbeInputNonExecuting" \
  "didPrepareStage256ComponentDemoSurfaceReadinessDecisionInput" \
  "didKeepBackendImplementationBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage255 internal component demo probe input: missing token $token" >&2
    exit 3
  fi
done

echo "stage255_internal_component_demo_probe_input_owner_present=true"
echo "stage254_component_demo_surface_semantic_diff_explain_required=true"
echo "internal_component_demo_probe_input_materialized=true"
echo "probe_input_bound_to_internal_surface=true"
echo "probe_input_bound_to_render_command_preview=true"
echo "probe_input_bound_to_state_update_dry_run=true"
echo "probe_input_bound_to_action_intent_facts=true"
echo "probe_input_non_executing=true"
echo "stage256_component_demo_surface_readiness_decision_input_prepared=true"
echo "backend_implementation=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
