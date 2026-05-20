#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage149 semantic comparator bridge owner 只整理
# stage148 source bridge envelope，不准做 live comparison admission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage149_semantic_comparator_bridge_after_stage148_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage149 semantic comparator bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage149SemanticComparatorBridgeAfterStage148FirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage149SemanticComparatorBridgeAfterStage148FirstSliceDraft" \
  "didRequireSemanticComparatorBridgeSourceReady" \
  "didRequireLiveBaselineCompareBeforeRuntimeAdmission" \
  "didKeepSemanticComparatorBridgeSourceOnly" \
  "didKeepSemanticAcceptanceRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage149 semantic comparator bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage149_semantic_comparator_bridge_after_stage148_owner_present=true"
echo "stage148_baseline_fixture_bridge_packet_required=true"
echo "semantic_comparator_bridge_source_ready_required=true"
echo "live_baseline_compare_before_runtime_admission_required=true"
echo "backend_ready_truth_before_runtime_admission_required=true"
echo "semantic_comparator_bridge_source_only=true"
echo "semantic_comparator_bridge_runtime_non_admitting=true"
echo "semantic_acceptance_runtime_admitted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
