#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage148 baseline fixture bridge focused suite。
# 它把 stage145 baseline / semantic verification contract 与已有 semantic
# comparison dry-run fixture 资产桥接起来，只产出 source-level comparator 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE148_TMPDIR:-/tmp/cjgui-stage148-baseline-fixture-bridge-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage148_baseline_fixture_bridge_after_stage145_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage148-baseline-fixture-bridge-after-stage145-suite.packet"

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
    echo "cjgui stage148 baseline fixture bridge suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage148 baseline fixture bridge suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage148 baseline fixture bridge suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: owner probe failed" >&2
  echo "cjgui stage148 baseline fixture bridge suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage148_baseline_fixture_bridge_after_stage145_owner_present=true" \
  "stage145_baseline_semantic_packet_required=true" \
  "legacy_semantic_comparison_fixture_packet_required=true" \
  "baseline_fixture_bridge_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: packet failed" >&2
  echo "cjgui stage148 baseline fixture bridge suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'baseline_fixture_bridge_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage148 baseline fixture bridge suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage148_baseline_fixture_bridge_after_stage145_first_slice_packet_passed=true" \
  "stage145_baseline_semantic_packet_consumed=true" \
  "legacy_semantic_comparison_fixture_packet_consumed=true" \
  "baseline_fixture_source_contract_bound=true" \
  "semantic_comparator_source_contract_bound=true" \
  "baseline_fixture_bridge_ready=true" \
  "baseline_fixture_bridge_runtime_admitted=false" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "baseline_fixture_bridge_route_classification")"
case "$route" in
  baseline_fixture_bridge_source_ready_runtime_blocked_host_metal_device_unavailable|\
  baseline_fixture_bridge_source_ready_runtime_blocked_missing_stage145_runtime_input|\
  baseline_fixture_bridge_source_ready_runtime_pending_metal_capable_rerun)
    require_file_fact "$packet" "baseline_fixture_bridge_runtime_admitted=false"
    ;;
  *)
    echo "cjgui stage148 baseline fixture bridge suite: unexpected route $route" >&2
    exit 9
    ;;
esac

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage148 baseline fixture bridge suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage148 baseline fixture bridge suite: runtime package build failed" >&2
  echo "cjgui stage148 baseline fixture bridge suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage148_baseline_fixture_bridge_after_stage145_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "baseline_fixture_bridge_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage148_owner_probe_passed=true"
  echo "stage148_baseline_fixture_bridge_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage148_public_foreign_scan_passed=true"
  echo "stage148_forbidden_native_render_token_scan_passed=true"
  echo "stage148_protected_path_scan_passed=true"
  echo "baseline_fixture_bridge_route_classification=$route"
  grep -E '^baseline_fixture_source_contract_bound=' "$packet" | tail -1
  grep -E '^semantic_comparator_source_contract_bound=' "$packet" | tail -1
  grep -E '^legacy_semantic_comparison_positive_fixture_matched=' "$packet" | tail -1
  grep -E '^legacy_semantic_comparison_negative_fixture_rejected=' "$packet" | tail -1
  grep -E '^stage145_baseline_semantic_runtime_input_ready=' "$packet" | tail -1
  echo "baseline_fixture_bridge_ready=true"
  echo "baseline_fixture_bridge_runtime_admitted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=semantic_comparator_bridge_after_stage148"
  echo "stage148_baseline_fixture_bridge_after_stage145_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage148 baseline fixture bridge suite: route_classification=stage148_baseline_fixture_bridge_after_stage145_first_slice_suite"
echo "cjgui stage148 baseline fixture bridge suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage148 baseline fixture bridge suite: renderer_state_write=false"
