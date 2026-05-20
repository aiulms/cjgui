#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage130 frame-hash persistence evidence /
# production-truth promotion predicate / renderer-state write admission
# recheck 连续阶段包 focused suite。它保持 non-mutating stop-line。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE130_TMPDIR:-/tmp/cjgui-stage130-admission-recheck-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

FRAME_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_evidence_envelope_first_slice_owner.sh"
PROMOTION_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_predicate_map_first_slice_owner.sh"
RECHECK_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_admission_recheck_first_slice_owner.sh"
FRAME_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_evidence_envelope_first_slice_packet.sh"
PROMOTION_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_predicate_map_first_slice_packet.sh"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_admission_recheck_first_slice_packet.sh"

FRAME_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_frame_hash_persistence_evidence_envelope_first_slice.cj"
PROMOTION_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_promotion_predicate_map_first_slice.cj"
RECHECK_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_admission_recheck_first_slice.cj"

FRAME_OWNER_LOG="$TMP_DIR/frame-owner.log"
PROMOTION_OWNER_LOG="$TMP_DIR/promotion-owner.log"
RECHECK_OWNER_LOG="$TMP_DIR/recheck-owner.log"
FRAME_PACKET_LOG="$TMP_DIR/frame-packet.log"
PROMOTION_PACKET_LOG="$TMP_DIR/promotion-packet.log"
RECHECK_PACKET_LOG="$TMP_DIR/recheck-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage130-renderer-state-write-admission-recheck-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$FRAME_OWNER_LOG"
: > "$PROMOTION_OWNER_LOG"
: > "$RECHECK_OWNER_LOG"
: > "$FRAME_PACKET_LOG"
: > "$PROMOTION_PACKET_LOG"
: > "$RECHECK_PACKET_LOG"
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
    echo "cjgui stage130 admission recheck suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in \
  "$FRAME_OWNER" \
  "$PROMOTION_OWNER" \
  "$RECHECK_OWNER" \
  "$FRAME_PACKET_SCRIPT" \
  "$PROMOTION_PACKET_SCRIPT" \
  "$RECHECK_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage130 admission recheck suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage130 admission recheck suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$FRAME_OWNER" > "$FRAME_OWNER_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: frame-hash owner failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$FRAME_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$PROMOTION_OWNER" > "$PROMOTION_OWNER_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: promotion owner failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$PROMOTION_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$RECHECK_OWNER" > "$RECHECK_OWNER_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: recheck owner failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$RECHECK_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "redacted_frame_hash_persistence_schema_defined=true" \
  "positive_live_probe_required_for_hash_persistence=true" \
  "production_truth_promotion_predicate_map_input_prepared=true"; do
  require_file_fact "$FRAME_OWNER_LOG" "$fact"
done
for fact in \
  "production_truth_promotion_predicate_map_ready=true" \
  "persisted_frame_hash_required_for_production_truth=true" \
  "renderer_state_write_admission_recheck_input_prepared=true"; do
  require_file_fact "$PROMOTION_OWNER_LOG" "$fact"
done
for fact in \
  "renderer_state_write_admission_recheck_ready=true" \
  "frame_hash_persistence_bound_to_renderer_state_write_admission=true" \
  "renderer_state_write_admission_ready=false"; do
  require_file_fact "$RECHECK_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage130-suite-frame-$$" \
  zsh "$FRAME_PACKET_SCRIPT" > "$FRAME_PACKET_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: frame-hash packet failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$FRAME_PACKET_LOG" >&2
  exit 9
fi
frame_packet="$(grep -Eo 'frame_hash_persistence_evidence_packet_path=[^[:space:]]+' "$FRAME_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$frame_packet" || ! -f "$frame_packet" ]]; then
  echo "cjgui stage130 admission recheck suite: missing frame-hash evidence packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage130-suite-promotion-$$" \
  CJGUI_STAGE130_FRAME_HASH_PERSISTENCE_EVIDENCE_PACKET="$frame_packet" \
  zsh "$PROMOTION_PACKET_SCRIPT" > "$PROMOTION_PACKET_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: promotion packet failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$PROMOTION_PACKET_LOG" >&2
  exit 11
fi
promotion_packet="$(grep -Eo 'production_truth_promotion_packet_path=[^[:space:]]+' "$PROMOTION_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$promotion_packet" || ! -f "$promotion_packet" ]]; then
  echo "cjgui stage130 admission recheck suite: missing production-truth promotion packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE130_TMPDIR="/tmp/cjgui-stage130-suite-recheck-$$" \
  CJGUI_STAGE130_PRODUCTION_TRUTH_PROMOTION_PACKET="$promotion_packet" \
  zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_PACKET_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: admission recheck packet failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$RECHECK_PACKET_LOG" >&2
  exit 13
fi
recheck_packet="$(grep -Eo 'renderer_state_write_admission_recheck_packet_path=[^[:space:]]+' "$RECHECK_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$recheck_packet" || ! -f "$recheck_packet" ]]; then
  echo "cjgui stage130 admission recheck suite: missing renderer-state write admission recheck packet" >&2
  exit 14
fi

for fact in \
  "stage130_frame_hash_persistence_evidence_envelope_first_slice_packet_passed=true" \
  "frame_hash_persistence_evidence_envelope_ready=true" \
  "redacted_frame_hash_persistence_schema_defined=true" \
  "frame_hash_persisted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$frame_packet" "$fact"
done
for fact in \
  "stage130_production_truth_promotion_predicate_map_first_slice_packet_passed=true" \
  "production_truth_promotion_predicate_map_ready=true" \
  "production_truth_promotion_predicates_materialized=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$promotion_packet" "$fact"
done
for fact in \
  "stage130_renderer_state_write_admission_recheck_first_slice_packet_passed=true" \
  "renderer_state_write_admission_recheck_ready=true" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write_blocked_by_frame_hash_persistence=true" \
  "frame_hash_persistence_backing_store_next_route_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$recheck_packet" "$fact"
done

for owner_file in \
  "$FRAME_OWNER_FILE" \
  "$PROMOTION_OWNER_FILE" \
  "$RECHECK_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage130 admission recheck suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage130 admission recheck suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage130 admission recheck suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage130 admission recheck suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage130 admission recheck suite: runtime package build failed" >&2
  echo "cjgui stage130 admission recheck suite: log=$BUILD_LOG" >&2
  exit 19
fi

probe_positive="$(fact_value "$frame_packet" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$frame_packet" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$frame_packet" "cjgui_harness_gap_detected")"
positive_probe_frame_hash_input="$(fact_value "$frame_packet" "positive_probe_frame_hash_input_available")"
runtime_native_probe_execution="$(fact_value "$recheck_packet" "runtime_native_probe_execution")"
renderer_state_write_blocked_by_probe="$(fact_value "$recheck_packet" "renderer_state_write_blocked_by_probe_classification")"

{
  echo "stage130_renderer_state_write_admission_recheck_first_slice_suite_version=1"
  echo "frame_owner_log=$FRAME_OWNER_LOG"
  echo "promotion_owner_log=$PROMOTION_OWNER_LOG"
  echo "recheck_owner_log=$RECHECK_OWNER_LOG"
  echo "frame_packet_log=$FRAME_PACKET_LOG"
  echo "promotion_packet_log=$PROMOTION_PACKET_LOG"
  echo "recheck_packet_log=$RECHECK_PACKET_LOG"
  echo "frame_hash_persistence_evidence_packet=$frame_packet"
  echo "production_truth_promotion_packet=$promotion_packet"
  echo "renderer_state_write_admission_recheck_packet=$recheck_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage130_frame_hash_persistence_evidence_owner_probe_passed=true"
  echo "stage130_production_truth_promotion_predicate_owner_probe_passed=true"
  echo "stage130_renderer_state_write_admission_recheck_owner_probe_passed=true"
  echo "stage130_frame_hash_persistence_evidence_packet_passed=true"
  echo "stage130_production_truth_promotion_packet_passed=true"
  echo "stage130_renderer_state_write_admission_recheck_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage130_public_foreign_scan_passed=true"
  echo "stage130_forbidden_native_render_token_scan_passed=true"
  echo "stage130_protected_path_scan_passed=true"
  echo "frame_hash_persistence_evidence_envelope_ready=true"
  echo "redacted_frame_hash_persistence_schema_defined=true"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "frame_hash_persisted=false"
  echo "production_truth_promotion_predicate_map_ready=true"
  echo "production_truth_promotion_predicates_materialized=true"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "renderer_state_write_admission_recheck_ready=true"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write_blocked_by_probe_classification=$renderer_state_write_blocked_by_probe"
  echo "frame_hash_persistence_backing_store_next_route_prepared=true"
  echo "next_route=frame_hash_persistence_backing_store_contract_first_slice"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "stage130_renderer_state_write_admission_recheck_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage130 admission recheck suite: route_classification=stage130_renderer_state_write_admission_recheck_first_slice_suite"
echo "cjgui stage130 admission recheck suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage130 admission recheck suite: renderer_state_write_admission_ready=false"
echo "cjgui stage130 admission recheck suite: renderer_state_write=false"
