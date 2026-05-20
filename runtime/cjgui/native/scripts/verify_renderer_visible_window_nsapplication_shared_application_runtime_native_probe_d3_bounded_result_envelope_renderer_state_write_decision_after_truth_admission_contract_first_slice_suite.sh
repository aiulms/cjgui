#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage144 renderer-state write decision after truth
# admission contract focused suite。它消费 stage143 packet，验证 write decision
# denial envelope、build 与 protected/public/forbidden scans。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE144_TMPDIR:-/tmp/cjgui-stage144-renderer-state-write-decision-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_after_truth_admission_contract_first_slice"
OWNER_SCRIPT="$SCRIPT_DIR/${PREFIX}_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/${PREFIX}_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_after_truth_admission_contract_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage144-renderer-state-write-decision-after-truth-admission-contract-suite.packet"

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
    echo "cjgui stage144 renderer-state write decision suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage144 renderer-state write decision suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage144 renderer-state write decision suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: owner probe failed" >&2
  echo "cjgui stage144 renderer-state write decision suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage144_renderer_state_write_decision_after_truth_admission_contract_owner_present=true" \
  "stage143_truth_admission_packet_required=true" \
  "production_render_truth_before_renderer_state_write_required=true" \
  "backend_ready_truth_before_renderer_state_write_required=true" \
  "renderer_state_write_decision_non_mutating=true" \
  "renderer_state_write_allowed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: packet failed" >&2
  echo "cjgui stage144 renderer-state write decision suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'write_decision_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage144 renderer-state write decision suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_packet_passed=true" \
  "stage143_truth_admission_packet_consumed=true" \
  "renderer_state_write_decision_ready=true" \
  "renderer_state_write_allowed=false" \
  "renderer_state_write_denied=true" \
  "renderer_state_write_decision_non_mutating=true" \
  "state_mutation_executed=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "renderer_state_write_decision_route_classification")"
case "$route" in
  renderer_state_write_decision_denied_host_metal_device_unavailable|\
  renderer_state_write_decision_denied_host_window_capture_unavailable|\
  renderer_state_write_decision_denied_missing_truth_or_admission|\
  renderer_state_write_decision_denied_pending_production_truth_and_write_admission|\
  renderer_state_write_decision_pending_explicit_production_write_admission)
    require_file_fact "$packet" "renderer_state_write_allowed=false"
    ;;
  *)
    echo "cjgui stage144 renderer-state write decision suite: unexpected route $route" >&2
    exit 9
    ;;
esac

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage144 renderer-state write decision suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage144 renderer-state write decision suite: runtime package build failed" >&2
  echo "cjgui stage144 renderer-state write decision suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "write_decision_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage144_owner_probe_passed=true"
  echo "stage144_write_decision_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage144_public_foreign_scan_passed=true"
  echo "stage144_forbidden_native_render_token_scan_passed=true"
  echo "stage144_protected_path_scan_passed=true"
  echo "renderer_state_write_decision_route_classification=$route"
  grep -E '^stage143_truth_admission_route_classification=' "$packet" | tail -1
  grep -E '^truth_admission_preflight_ready=' "$packet" | tail -1
  grep -E '^positive_first_frame_input_ready=' "$packet" | tail -1
  grep -E '^production_render_truth=' "$packet" | tail -1
  grep -E '^backend_ready_truth=' "$packet" | tail -1
  grep -E '^renderer_state_write_denial_reason=' "$packet" | tail -1
  echo "renderer_state_write_decision_ready=true"
  echo "renderer_state_write_allowed=false"
  echo "renderer_state_write_denied=true"
  echo "renderer_state_write_decision_non_mutating=true"
  echo "state_mutation_executed=false"
  echo "visibility_published=false"
  echo "runtime_state_write=false"
  echo "renderer_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=positive_rerun_through_first_frame_or_baseline_semantic_verification"
  echo "stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage144 renderer-state write decision suite: route_classification=stage144_renderer_state_write_decision_after_truth_admission_contract_first_slice_suite"
echo "cjgui stage144 renderer-state write decision suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage144 renderer-state write decision suite: write_decision_route=$route"
echo "cjgui stage144 renderer-state write decision suite: renderer_state_write=false"
