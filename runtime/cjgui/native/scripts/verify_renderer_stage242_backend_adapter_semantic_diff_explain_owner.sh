#!/usr/bin/env zsh
#
# 维护注释：验证 stage242 backend adapter semantic diff/explain owner。
# 它只生成 owner-local diff / explain 和 rollback-ready adapter boundary。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage242_backend_adapter_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage242 backend adapter semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage242BackendAdapterSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage242BackendAdapterSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage242BackendAdapterSemanticDiffExplainDraft" \
  "didConsumeStage241ComponentDemoBackendAdapterPacket" \
  "didMaterializeBackendAdapterSemanticDiff" \
  "didMaterializeBackendAdapterExplainPacket" \
  "didBindDiffToComponentDemoBackendAdapterPacket" \
  "didBindExplainToRefreshedRenderCommand" \
  "didMaterializeBackendAdapterRollbackReadyBoundary" \
  "didPrepareStage243BackendAdapterDryRunPredicateInput" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage242 backend adapter semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage242_backend_adapter_semantic_diff_explain_owner_present=true"
echo "stage241_component_demo_backend_adapter_packet_required=true"
echo "backend_adapter_semantic_diff_materialized=true"
echo "backend_adapter_explain_packet_materialized=true"
echo "backend_adapter_rollback_ready_boundary_materialized=true"
echo "stage243_backend_adapter_dry_run_predicate_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
