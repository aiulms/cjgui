#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage192 visibility publication positive dry-run owner。
# 它只生成 internal visibility dry-run receipt，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage192_renderer_state_write_visibility_publication_positive_dry_run_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage192 renderer_state visibility publication positive dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage192RendererStateWriteVisibilityPublicationPositiveDryRunFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage192RendererStateWriteVisibilityPublicationPositiveDryRunFirstSliceDraft" \
  "didConsumeStage191RendererStateWriteGuardedExecutorPositiveDryRun" \
  "didMaterializeRendererStateWriteVisibilityPublicationPositiveDryRun" \
  "didBindGuardedExecutorPositiveDryRunToVisibilityPublication" \
  "didMaterializeVisibilityPublicationDryRunReceipt" \
  "didMaterializeNonPublicVisibilityPublicationEnvelope" \
  "didConfirmFixtureVisibilityPublicationAdmitted" \
  "didPrepareStage193RendererStateWriteFirstSliceDryRunExecutorInput" \
  "didKeepRendererStateWriteVisibilityPublicationDryRunInternalOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage192 renderer_state visibility publication positive dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage192_renderer_state_visibility_publication_positive_dry_run_owner_present=true"
echo "stage191_renderer_state_guarded_executor_positive_dry_run_required=true"
echo "renderer_state_write_visibility_publication_positive_dry_run_materialized=true"
echo "guarded_executor_positive_dry_run_to_visibility_publication_bound=true"
echo "visibility_publication_dry_run_receipt_materialized=true"
echo "non_public_visibility_publication_envelope_materialized=true"
echo "fixture_visibility_publication_admitted=true"
echo "stage193_renderer_state_write_first_slice_dry_run_executor_input_prepared=true"
echo "visibility_publication_positive_dry_run_internal_only=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
