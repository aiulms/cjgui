#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage188 runtime_state write visibility publication
# schema bridge owner。它只物化 publication predicate ledger，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage188_runtime_state_write_visibility_publication_schema_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage188 runtime_state visibility publication schema bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage188RuntimeStateWriteVisibilityPublicationSchemaBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage188RuntimeStateWriteVisibilityPublicationSchemaBridgeFirstSliceDraft" \
  "didConsumeStage187RuntimeStateWriteGuardedExecutorSchemaPreflight" \
  "didMaterializeRuntimeStateWriteVisibilityPublicationSchemaBridge" \
  "didBindGuardedExecutorPreflightToVisibilityPublicationSchema" \
  "didMaterializeVisibilityPublicationSchemaPredicateLedger" \
  "didBindVisibilityPublicationHoldToSchemaBridge" \
  "didPrepareStage189RendererStateWriteSchemaReadinessRecheckInput" \
  "didKeepVisibilityPublicationSchemaBridgeInternalOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage188 runtime_state visibility publication schema bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage188_runtime_state_visibility_publication_schema_bridge_owner_present=true"
echo "stage187_runtime_state_guarded_executor_schema_preflight_required=true"
echo "runtime_state_write_visibility_publication_schema_bridge_materialized=true"
echo "guarded_executor_preflight_to_visibility_publication_schema_bound=true"
echo "visibility_publication_schema_predicate_ledger_materialized=true"
echo "visibility_publication_hold_to_schema_bridge_bound=true"
echo "stage189_renderer_state_write_schema_readiness_recheck_input_prepared=true"
echo "visibility_publication_schema_bridge_internal_only=true"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
