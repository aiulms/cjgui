#!/usr/bin/env zsh
#
# 维护注释：stage175 focused suite 验证 commit dry-run ->
# rollback-ready result envelope，并保持结果 owner-local、non-mutating。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE175_TMPDIR:-/tmp/cjgui-stage175-renderer-state-write-rollback-ready-result-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage175-renderer-state-write-rollback-ready-result-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
: > "$BUILD_LOG"
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
    echo "cjgui stage175 renderer-state write rollback-ready result suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$OWNER_SCRIPT" "$PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage175 renderer-state write rollback-ready result suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage175 renderer-state write rollback-ready result suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: owner probe failed" >&2
  echo "cjgui stage175 renderer-state write rollback-ready result suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage175_renderer_state_write_rollback_ready_result_owner_present=true" \
  "rollback_ready_result_envelope_materialized=true" \
  "commit_dry_run_result_to_rollback_readiness_bound=true" \
  "rollback_snapshot_owner_local_only=true" \
  "stage176_visibility_not_published_boundary_input_prepared=true" \
  "rollback_ready_result_non_mutating=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write_rollback_ready_result_ready=true" \
  "renderer_state_write_rollback_ready_result_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: packet failed" >&2
  echo "cjgui stage175 renderer-state write rollback-ready result suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'renderer_state_write_rollback_ready_result_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage175_renderer_state_write_rollback_ready_result_packet_passed=true" \
  "stage174_renderer_state_write_commit_dry_run_consumed=true" \
  "renderer_state_write_rollback_ready_result_ready=true" \
  "renderer_state_write_rollback_ready_result_source_ready=true" \
  "renderer_state_write_rollback_ready_result_runtime_admitted=false" \
  "rollback_ready_result_envelope_materialized=true" \
  "commit_dry_run_result_to_rollback_readiness_bound=true" \
  "rollback_snapshot_owner_local_only=true" \
  "rollback_ready_result_non_mutating=true" \
  "stage176_visibility_not_published_boundary_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write_execution_blocked=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "renderer_state_write_rollback_ready_result_route_classification")"
if [[ "$route" != "renderer_state_write_rollback_ready_result_envelope_ready_non_mutating" ]]; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: unexpected route $route" >&2
  exit 9
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result suite: runtime package build failed" >&2
  echo "cjgui stage175 renderer-state write rollback-ready result suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage175_renderer_state_write_rollback_ready_result_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "renderer_state_write_rollback_ready_result_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage175_owner_probe_passed=true"
  echo "stage175_renderer_state_write_rollback_ready_result_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage175_public_foreign_scan_passed=true"
  echo "stage175_forbidden_native_render_token_scan_passed=true"
  echo "stage175_protected_path_scan_passed=true"
  echo "renderer_state_write_rollback_ready_result_route_classification=$route"
  echo "renderer_state_write_rollback_ready_result_ready=true"
  echo "renderer_state_write_rollback_ready_result_source_ready=true"
  echo "renderer_state_write_rollback_ready_result_runtime_admitted=false"
  echo "rollback_ready_result_envelope_materialized=true"
  echo "commit_dry_run_result_to_rollback_readiness_bound=true"
  echo "rollback_snapshot_owner_local_only=true"
  echo "rollback_ready_result_non_mutating=true"
  echo "stage176_visibility_not_published_boundary_input_prepared=true"
  echo "visibility_publication_blocked=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage176_renderer_state_write_visibility_not_published_boundary_after_rollback_ready_result"
  echo "stage175_renderer_state_write_rollback_ready_result_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage175 renderer-state write rollback-ready result suite: route_classification=stage175_renderer_state_write_rollback_ready_result_suite"
echo "cjgui stage175 renderer-state write rollback-ready result suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage175 renderer-state write rollback-ready result suite: renderer_state_write=false"
