#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage153 guarded executor bridge focused suite。
# 它消费 stage152 mutation request bridge 与既有 guarded executor result
# envelope，将 visibility publication denial input 接到新主线。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE153_TMPDIR:-/tmp/cjgui-stage153-guarded-executor-bridge-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage153-guarded-executor-bridge-after-mutation-request-bridge-suite.packet"

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
    echo "cjgui stage153 guarded executor bridge suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage153 guarded executor bridge suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage153 guarded executor bridge suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: owner probe failed" >&2
  echo "cjgui stage153 guarded executor bridge suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage153_guarded_executor_bridge_after_mutation_request_bridge_owner_present=true" \
  "stage152_mutation_request_bridge_packet_required=true" \
  "legacy_guarded_executor_result_envelope_required=true" \
  "guarded_executor_denial_bound_to_stage152_bridge=true" \
  "visibility_publication_denial_input_prepared=true" \
  "guarded_executor_bridge_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: packet failed" >&2
  echo "cjgui stage153 guarded executor bridge suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'guarded_executor_bridge_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage153 guarded executor bridge suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_packet_passed=true" \
  "stage152_mutation_request_bridge_packet_consumed=true" \
  "legacy_guarded_executor_result_envelope_consumed=true" \
  "guarded_executor_bridge_ready=true" \
  "guarded_executor_bridge_source_ready=true" \
  "guarded_executor_bridge_runtime_admitted=false" \
  "visibility_publication_denial_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "guarded_executor_denied=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "guarded_executor_bridge_route_classification")"
case "$route" in
  guarded_executor_bridge_source_ready_runtime_blocked_host_metal_device_unavailable|\
  guarded_executor_bridge_source_ready_runtime_blocked_mutation_request_bridge|\
  guarded_executor_bridge_source_ready_runtime_blocked_guarded_executor_denied)
    require_file_fact "$packet" "guarded_executor_bridge_runtime_admitted=false"
    ;;
  *)
    echo "cjgui stage153 guarded executor bridge suite: unexpected route $route" >&2
    exit 9
    ;;
esac

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage153 guarded executor bridge suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage153 guarded executor bridge suite: runtime package build failed" >&2
  echo "cjgui stage153 guarded executor bridge suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "guarded_executor_bridge_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage153_owner_probe_passed=true"
  echo "stage153_guarded_executor_bridge_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage153_public_foreign_scan_passed=true"
  echo "stage153_forbidden_native_render_token_scan_passed=true"
  echo "stage153_protected_path_scan_passed=true"
  echo "guarded_executor_bridge_route_classification=$route"
  grep -E '^mutation_request_bridge_runtime_admitted=' "$packet" | tail -1
  echo "guarded_executor_bridge_ready=true"
  echo "guarded_executor_bridge_source_ready=true"
  echo "guarded_executor_bridge_runtime_admitted=false"
  echo "visibility_publication_denial_input_prepared=true"
  echo "visibility_publication_blocked=true"
  echo "guarded_executor_denied=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=visibility_publication_denial_after_guarded_executor_bridge_or_metal_capable_rerun"
  echo "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage153 guarded executor bridge suite: route_classification=stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_suite"
echo "cjgui stage153 guarded executor bridge suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage153 guarded executor bridge suite: renderer_state_write=false"
