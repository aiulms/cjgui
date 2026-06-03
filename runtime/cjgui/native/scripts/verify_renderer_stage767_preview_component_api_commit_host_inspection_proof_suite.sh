#!/usr/bin/env zsh
#
# Focused suite for stage767. It consumes stage766 and records preview component
# API commit host inspection proof evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE767_TMPDIR:-/private/tmp/cjgui-stage765-stage768/stage767}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
PUBLIC_SCAN_LOG="$TMP_DIR/public-declaration-scan.log"
SUITE_PACKET="$TMP_DIR/stage767-preview-component-api-commit-host-inspection-proof-suite.packet"
STAGE766_SUITE_PACKET="${CJGUI_STAGE767_INPUT_PACKET:-${CJGUI_STAGE766_PREVIEW_COMPONENT_API_COMMIT_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage765-stage768/stage766/stage766-preview-component-api-commit-rollback-snapshot-suite.packet}}"
STAGE766_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage766_preview_component_api_commit_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage767_preview_component_api_commit_host_inspection_proof_owner.sh"
OWNER_LOG="$TMP_DIR/stage767-preview-component-api-commit-host-inspection-proof-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$BUILD_LOG"
: > "$PUBLIC_SCAN_LOG"
: > "$SUITE_PACKET"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

ensure_toolchain() {
  if command -v cjpm >/dev/null 2>&1 && command -v cjc >/dev/null 2>&1; then
    return
  fi
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    export PATH="$PS_SHIM_DIR:$PATH"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage767 preview component api commit host inspection proof suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE766_SUITE_PACKET" ]] || ! grep -F "stage766_preview_component_api_commit_rollback_snapshot_suite_passed=true" "$STAGE766_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE766_TMPDIR="$TMP_DIR/stage766" zsh "$STAGE766_SUITE_SCRIPT" >/dev/null
  STAGE766_SUITE_PACKET="$TMP_DIR/stage766/stage766-preview-component-api-commit-rollback-snapshot-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage766_preview_component_api_commit_rollback_snapshot_consumed=true" \
  "preview_component_api_commit_rollback_snapshot_ledger_consumed=true" \
  "preview_component_api_commit_host_inspection_rows_materialized=true" \
  "preview_component_api_commit_slot_diff_rows_materialized=true" \
  "preview_component_api_commit_compatibility_review_rows_materialized=true" \
  "preview_component_api_commit_result_surface_refresh_materialized=true" \
  "chat_composer_preview_component_api_commit_host_inspection_surface_materialized=true" \
  "stage768_preview_component_api_commit_runtime_manager_prepared=true" \
  "new_public_surface_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage766_preview_component_api_commit_rollback_snapshot_suite_passed=true" \
  "preview_component_api_commit_rollback_base_snapshot_materialized=true" \
  "preview_component_api_commit_rollback_token_ledger_materialized=true"; do
  require_file_fact "$STAGE766_SUITE_PACKET" "$fact"
done

for src in "$ROOT_DIR/src/runtime_renderer_stage767_preview_component_api_commit_host_inspection_proof.cj"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage767 preview component api commit host inspection proof suite: missing source $src" >&2
    exit 10
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' >/dev/null 2>&1; then
    echo "cjgui stage767 preview component api commit host inspection proof suite: unexpected public or foreign declaration in $src" >&2
    exit 11
  fi
done

grep -R -nE '^public[[:space:]]+(func|struct|class|enum|let|var)' "$ROOT_DIR/src" > "$PUBLIC_SCAN_LOG" || true
require_file_fact "$PUBLIC_SCAN_LOG" "cjguiExperimentalComponentPreviewApiReady"
if grep -E 'runtime_renderer_stage76[5-7].*public[[:space:]]+' "$PUBLIC_SCAN_LOG" >/dev/null 2>&1; then
  echo "cjgui stage767 preview component api commit host inspection proof suite: unexpected stage765-767 public declaration" >&2
  exit 13
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage767 preview component api commit host inspection proof suite: protected production bridge/state path modified" >&2
  exit 14
fi

ensure_toolchain
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage767 preview component api commit host inspection proof suite: runtime package build failed" >&2
  echo "cjgui stage767 preview component api commit host inspection proof suite: log=$BUILD_LOG" >&2
  exit 16
fi

{
  echo "stage767_preview_component_api_commit_host_inspection_proof_suite_version=1"
  echo "stage766_preview_component_api_commit_rollback_snapshot_suite_packet=$STAGE766_SUITE_PACKET"
  echo "build_log=$BUILD_LOG"
  echo "public_declaration_scan_log=$PUBLIC_SCAN_LOG"
  cat "$OWNER_LOG"
  echo "runtime_package_build_passed=true"
  echo "stage765_stage767_public_declaration_scan_passed=true"
  echo "stage767_forbidden_native_render_token_scan_passed=true"
  echo "stage767_protected_path_scan_passed=true"
  echo "new_public_surface=none"
  echo "public_surface_stability_unchanged=experimental_preview"
  echo "next_route=stage768_preview_component_api_commit_runtime_manager_after_stage767"
  echo "stage767_preview_component_api_commit_host_inspection_proof_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage767 preview component api commit host inspection proof suite: route_classification=public_preview_api_commit_host_inspection_proof"
echo "cjgui stage767 preview component api commit host inspection proof suite: suite_packet_path=$SUITE_PACKET"
