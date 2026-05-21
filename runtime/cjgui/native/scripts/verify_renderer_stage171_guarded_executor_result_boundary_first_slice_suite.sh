#!/usr/bin/env zsh
#
# 维护注释：stage171 focused suite 验证 guarded executor result envelope ->
# result boundary，并输出 visibility publication admission 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE171_TMPDIR:-/tmp/cjgui-stage171-guarded-executor-result-boundary-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage171_guarded_executor_result_boundary_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage171_guarded_executor_result_boundary_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage171_guarded_executor_result_boundary_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage171-guarded-executor-result-boundary-first-slice-suite.packet"

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
    echo "cjgui stage171 guarded executor result boundary suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage171 guarded executor result boundary suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage171 guarded executor result boundary suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: owner probe failed" >&2
  echo "cjgui stage171 guarded executor result boundary suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage171_guarded_executor_result_boundary_owner_present=true" \
  "guarded_executor_result_boundary_envelope_materialized=true" \
  "guarded_executor_denial_reason_ledger_bound=true" \
  "rollback_eligibility_boundary_bound=true" \
  "stage172_visibility_publication_admission_input_prepared=true" \
  "guarded_executor_result_boundary_ready=true" \
  "guarded_executor_result_boundary_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: packet failed" >&2
  echo "cjgui stage171 guarded executor result boundary suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'guarded_executor_result_boundary_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage171 guarded executor result boundary suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage171_guarded_executor_result_boundary_packet_passed=true" \
  "stage170_guarded_state_write_executor_consumed=true" \
  "guarded_executor_result_boundary_ready=true" \
  "guarded_executor_result_boundary_source_ready=true" \
  "guarded_executor_result_boundary_runtime_admitted=false" \
  "guarded_executor_result_boundary_envelope_materialized=true" \
  "guarded_executor_denial_reason_ledger_bound=true" \
  "rollback_eligibility_boundary_bound=true" \
  "guarded_executor_result_boundary_non_mutating=true" \
  "guarded_executor_result_boundary_predicates_satisfied=false" \
  "stage172_visibility_publication_admission_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "guarded_executor_result_boundary_route_classification")"
case "$route" in
  guarded_executor_result_boundary_blocked_host_metal_device_unavailable|\
  guarded_executor_result_boundary_blocked_guarded_executor_admission|\
  guarded_executor_result_boundary_ready_for_visibility_publication_admission)
    require_file_fact "$packet" "guarded_executor_result_boundary_runtime_admitted=false"
    ;;
  *)
    echo "cjgui stage171 guarded executor result boundary suite: unexpected route $route" >&2
    exit 9
    ;;
esac

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage171 guarded executor result boundary suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage171 guarded executor result boundary suite: runtime package build failed" >&2
  echo "cjgui stage171 guarded executor result boundary suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage171_guarded_executor_result_boundary_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "guarded_executor_result_boundary_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage171_owner_probe_passed=true"
  echo "stage171_guarded_executor_result_boundary_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage171_public_foreign_scan_passed=true"
  echo "stage171_forbidden_native_render_token_scan_passed=true"
  echo "stage171_protected_path_scan_passed=true"
  echo "guarded_executor_result_boundary_route_classification=$route"
  echo "guarded_executor_result_boundary_ready=true"
  echo "guarded_executor_result_boundary_source_ready=true"
  echo "guarded_executor_result_boundary_runtime_admitted=false"
  echo "guarded_executor_result_boundary_envelope_materialized=true"
  echo "guarded_executor_denial_reason_ledger_bound=true"
  echo "rollback_eligibility_boundary_bound=true"
  echo "stage172_visibility_publication_admission_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage172_visibility_publication_admission_after_guarded_executor_result_boundary"
  echo "stage171_guarded_executor_result_boundary_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage171 guarded executor result boundary suite: route_classification=stage171_guarded_executor_result_boundary_suite"
echo "cjgui stage171 guarded executor result boundary suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage171 guarded executor result boundary suite: renderer_state_write=false"
