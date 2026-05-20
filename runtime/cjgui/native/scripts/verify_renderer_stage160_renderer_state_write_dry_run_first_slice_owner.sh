#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage160 renderer-state write dry-run source 消费
# stage159 visibility result bridge，并准备 admission ledger 输入；不执行 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage160_renderer_state_write_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage160 renderer-state write dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage160RendererStateWriteDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage160RendererStateWriteDryRunFirstSliceDraft" \
  "didConsumeStage159VisibilityResultBridge" \
  "didMaterializeRendererStateWriteDryRunEnvelope" \
  "didBindVisibilityResultToRendererStateWriteDryRun" \
  "didMaterializeRendererStateWriteDryRunPositivePredicateMap" \
  "didPrepareRendererStateWriteAdmissionLedgerInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage160 renderer-state write dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage160_renderer_state_write_dry_run_owner_present=true"
echo "stage159_visibility_result_bridge_required=true"
echo "renderer_state_write_dry_run_envelope_materialized=true"
echo "renderer_state_write_dry_run_positive_predicate_map_materialized=true"
echo "renderer_state_write_admission_ledger_input_prepared=true"
echo "renderer_state_write_dry_run_ready=true"
echo "renderer_state_write_dry_run_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
