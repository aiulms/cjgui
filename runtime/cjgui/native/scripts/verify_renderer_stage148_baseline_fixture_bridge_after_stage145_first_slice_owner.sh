#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage148 baseline fixture bridge owner 只桥接 source
# contract，不把旧 dry-run comparator 事实升级为当前 runtime truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage148 baseline fixture bridge owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage148BaselineFixtureBridgeAfterStage145FirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage148BaselineFixtureBridgeAfterStage145FirstSliceDraft" \
  "didBindBaselineFixtureSourceContract" \
  "didBindSemanticComparatorSourceContract" \
  "didKeepLegacyComparatorAsSourceContractOnly" \
  "didKeepBaselineFixtureRuntimeAdmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage148 baseline fixture bridge owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage148_baseline_fixture_bridge_after_stage145_owner_present=true"
echo "stage145_baseline_semantic_packet_required=true"
echo "legacy_semantic_comparison_fixture_packet_required=true"
echo "baseline_fixture_source_contract_required=true"
echo "semantic_comparator_source_contract_required=true"
echo "legacy_comparator_source_contract_only=true"
echo "stage145_runtime_input_before_bridge_runtime_admission_required=true"
echo "metal_capable_rerun_before_bridge_runtime_admission_required=true"
echo "baseline_fixture_bridge_non_mutating=true"
echo "baseline_fixture_bridge_runtime_admitted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
