#!/usr/bin/env zsh
#
# 维护注释：stage197-200 focused suite 串联 truth/semantic recheck bridge、
# semantic admission gap ledger、promotion token recheck preflight 与 write
# readiness recheck join。它只生成 readiness/recheck packet，不做真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE197_200_TMPDIR:-/tmp/cjgui-stage197-200-truth-semantic-recheck-join-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE196_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage196_renderer_state_write_first_slice_readiness_boundary_first_slice_suite.sh"
STAGE150_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_packet.sh"
STAGE196_LOG="$TMP_DIR/stage196.log"
STAGE150_LOG="$TMP_DIR/stage150.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage200-write-readiness-recheck-join-suite.packet"
STAGE196_SUITE_PACKET="${CJGUI_STAGE196_RENDERER_STATE_WRITE_FIRST_SLICE_READINESS_BOUNDARY_SUITE_PACKET:-}"
STAGE150_PACKET="${CJGUI_STAGE150_PRODUCTION_TRUTH_RECHECK_PACKET:-}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage197_truth_semantic_recheck_bridge_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage198_semantic_admission_gap_ledger_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage199_promotion_token_recheck_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage200_write_readiness_recheck_join_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage197_truth_semantic_recheck_bridge.cj"
  "$ROOT_DIR/src/runtime_renderer_stage198_semantic_admission_gap_ledger.cj"
  "$ROOT_DIR/src/runtime_renderer_stage199_promotion_token_recheck_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_stage200_write_readiness_recheck_join.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE196_LOG"
: > "$STAGE150_LOG"
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
    echo "cjgui stage197-200 truth semantic recheck join suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE196_SUITE_SCRIPT" "$STAGE150_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage197-200 truth semantic recheck join suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage197-200 truth semantic recheck join suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage197-200 truth semantic recheck join suite: owner probe failed $script" >&2
    echo "cjgui stage197-200 truth semantic recheck join suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[2]}" "semantic_runtime_admission_gap_ledger_materialized=true"
require_file_fact "${owner_logs[3]}" "result_envelope_promotion_token_recheck_materialized=true"
require_file_fact "${owner_logs[4]}" "renderer_state_write_readiness_recheck_join_packet_materialized=true"
require_file_fact "${owner_logs[4]}" "stage201_write_token_reevaluation_input_prepared=true"

if [[ -n "$STAGE196_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE196_SUITE_PACKET" ]]; then
    echo "cjgui stage197-200 truth semantic recheck join suite: provided stage196 packet missing $STAGE196_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage196_suite_packet_used=true"
    echo "suite_packet_path=$STAGE196_SUITE_PACKET"
  } > "$STAGE196_LOG"
else
  if ! env CJGUI_STAGE196_TMPDIR="$TMP_DIR/stage196" zsh "$STAGE196_SUITE_SCRIPT" > "$STAGE196_LOG" 2>&1; then
    echo "cjgui stage197-200 truth semantic recheck join suite: stage196 suite failed" >&2
    echo "cjgui stage197-200 truth semantic recheck join suite: log=$STAGE196_LOG" >&2
    exit 8
  fi
  STAGE196_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE196_LOG" | tail -1 | cut -d= -f2-)"
fi
stage196_packet="$STAGE196_SUITE_PACKET"
if [[ -z "$stage196_packet" || ! -f "$stage196_packet" ]]; then
  echo "cjgui stage197-200 truth semantic recheck join suite: missing stage196 packet" >&2
  exit 9
fi
for fact in \
  "stage196_renderer_state_write_first_slice_readiness_boundary_suite_passed=true" \
  "renderer_state_write_first_slice_readiness_boundary_ready=true" \
  "production_truth_recheck_request_materialized=true" \
  "semantic_admission_recheck_request_materialized=true" \
  "stage197_renderer_state_write_production_truth_semantic_recheck_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$stage196_packet" "$fact"
done

if [[ -n "$STAGE150_PACKET" ]]; then
  if [[ ! -f "$STAGE150_PACKET" ]]; then
    echo "cjgui stage197-200 truth semantic recheck join suite: provided stage150 packet missing $STAGE150_PACKET" >&2
    exit 10
  fi
  {
    echo "provided_stage150_production_truth_recheck_packet_used=true"
    echo "production_truth_recheck_packet_path=$STAGE150_PACKET"
  } > "$STAGE150_LOG"
else
  if ! env CJGUI_STAGE150_PACKET_TMPDIR="$TMP_DIR/stage150" zsh "$STAGE150_PACKET_SCRIPT" > "$STAGE150_LOG" 2>&1; then
    echo "cjgui stage197-200 truth semantic recheck join suite: stage150 packet failed" >&2
    echo "cjgui stage197-200 truth semantic recheck join suite: log=$STAGE150_LOG" >&2
    exit 11
  fi
  STAGE150_PACKET="$(grep -Eo 'production_truth_recheck_packet_path=[^[:space:]]+' "$STAGE150_LOG" | tail -1 | cut -d= -f2-)"
fi
stage150_packet="$STAGE150_PACKET"
if [[ -z "$stage150_packet" || ! -f "$stage150_packet" ]]; then
  echo "cjgui stage197-200 truth semantic recheck join suite: missing stage150 packet" >&2
  exit 12
fi
for fact in \
  "stage150_production_truth_recheck_after_semantic_comparator_bridge_first_slice_packet_passed=true" \
  "stage149_semantic_comparator_bridge_packet_consumed=true" \
  "production_truth_recheck_ready=true" \
  "production_truth_recheck_allowed=false" \
  "semantic_acceptance_runtime_admitted=false" \
  "backend_ready_truth=false" \
  "production_render_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$stage150_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage197-200 truth semantic recheck join suite: missing owner source $src" >&2
    exit 13
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage197-200 truth semantic recheck join suite: public or foreign declaration found in $src" >&2
    exit 14
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage197-200 truth semantic recheck join suite: forbidden native/render token found in $src" >&2
    exit 15
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage197-200 truth semantic recheck join suite: protected production bridge/state path modified" >&2
  exit 16
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage197-200 truth semantic recheck join suite: cjpm unavailable" >&2
  exit 17
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage197-200 truth semantic recheck join suite: runtime package build failed" >&2
  echo "cjgui stage197-200 truth semantic recheck join suite: log=$BUILD_LOG" >&2
  exit 18
fi

stage150_route="$(fact_value "$stage150_packet" "production_truth_recheck_route_classification")"
stage196_route="$(fact_value "$stage196_packet" "renderer_state_write_first_slice_readiness_boundary_route_classification")"

{
  echo "stage197_200_truth_semantic_recheck_join_suite_version=1"
  echo "stage196_suite_packet=$stage196_packet"
  echo "stage150_production_truth_recheck_packet=$stage150_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage197_truth_semantic_recheck_bridge_owner_passed=true"
  echo "stage198_semantic_admission_gap_ledger_owner_passed=true"
  echo "stage199_promotion_token_recheck_preflight_owner_passed=true"
  echo "stage200_write_readiness_recheck_join_owner_passed=true"
  echo "stage196_readiness_boundary_consumed=true"
  echo "stage150_production_truth_recheck_consumed=true"
  echo "stage196_route_classification=$stage196_route"
  echo "stage150_route_classification=$stage150_route"
  echo "truth_semantic_recheck_bridge_ready=true"
  echo "production_truth_recheck_request_bound_to_stage150=true"
  echo "semantic_admission_recheck_request_bound_to_stage149=true"
  echo "semantic_runtime_admission_gap_ledger_materialized=true"
  echo "live_baseline_compare_requirement_materialized=true"
  echo "backend_ready_truth_requirement_materialized=true"
  echo "result_envelope_promotion_token_recheck_materialized=true"
  echo "promotion_token_missing_predicate_receipt_materialized=true"
  echo "renderer_state_write_readiness_recheck_join_packet_materialized=true"
  echo "write_token_reevaluation_missing_predicate_receipt_materialized=true"
  echo "stage201_write_token_reevaluation_input_prepared=true"
  echo "runtime_package_build_passed=true"
  echo "stage197_200_public_foreign_scan_passed=true"
  echo "stage197_200_forbidden_native_render_token_scan_passed=true"
  echo "stage197_200_protected_path_scan_passed=true"
  echo "renderer_state_write_eligibility=false"
  echo "result_envelope_promotion_token=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage201_renderer_state_write_token_reevaluation_after_truth_semantic_recheck_join"
  echo "stage197_200_truth_semantic_recheck_join_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage197-200 truth semantic recheck join suite: route_classification=stage200_write_readiness_recheck_join_ready"
echo "cjgui stage197-200 truth semantic recheck join suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage197-200 truth semantic recheck join suite: renderer_state_write=false"
