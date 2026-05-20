#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage129 truth gap matrix / bounded probe truth
# alignment / renderer-state write readiness closure 连续阶段包 focused suite。
# 它会执行真实 bounded first-frame native probe，并保持 production truth /
# renderer_state write 阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE129_TMPDIR:-/tmp/cjgui-stage129-write-readiness-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

TRUTH_GAP_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_truth_gap_matrix_first_slice_owner.sh"
ALIGNMENT_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_bounded_probe_truth_alignment_first_slice_owner.sh"
READINESS_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_owner.sh"
TRUTH_GAP_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_truth_gap_matrix_first_slice_packet.sh"
ALIGNMENT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet.sh"
READINESS_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet.sh"

TRUTH_GAP_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_truth_gap_matrix_first_slice.cj"
ALIGNMENT_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_bounded_probe_truth_alignment_first_slice.cj"
READINESS_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_renderer_state_write_readiness_closure_first_slice.cj"

TRUTH_GAP_OWNER_LOG="$TMP_DIR/truth-gap-owner.log"
ALIGNMENT_OWNER_LOG="$TMP_DIR/alignment-owner.log"
READINESS_OWNER_LOG="$TMP_DIR/readiness-owner.log"
TRUTH_GAP_PACKET_LOG="$TMP_DIR/truth-gap-packet.log"
ALIGNMENT_PACKET_LOG="$TMP_DIR/alignment-packet.log"
READINESS_PACKET_LOG="$TMP_DIR/readiness-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage129-terminal-write-denial-renderer-state-write-readiness-closure-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$TRUTH_GAP_OWNER_LOG"
: > "$ALIGNMENT_OWNER_LOG"
: > "$READINESS_OWNER_LOG"
: > "$TRUTH_GAP_PACKET_LOG"
: > "$ALIGNMENT_PACKET_LOG"
: > "$READINESS_PACKET_LOG"
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
    echo "cjgui stage129 write readiness suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in \
  "$TRUTH_GAP_OWNER" \
  "$ALIGNMENT_OWNER" \
  "$READINESS_OWNER" \
  "$TRUTH_GAP_PACKET_SCRIPT" \
  "$ALIGNMENT_PACKET_SCRIPT" \
  "$READINESS_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage129 write readiness suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage129 write readiness suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$TRUTH_GAP_OWNER" > "$TRUTH_GAP_OWNER_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: truth gap owner failed" >&2
  echo "cjgui stage129 write readiness suite: log=$TRUTH_GAP_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$ALIGNMENT_OWNER" > "$ALIGNMENT_OWNER_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: alignment owner failed" >&2
  echo "cjgui stage129 write readiness suite: log=$ALIGNMENT_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$READINESS_OWNER" > "$READINESS_OWNER_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: readiness owner failed" >&2
  echo "cjgui stage129 write readiness suite: log=$READINESS_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "production_truth_gap_matrix_ready=true" \
  "exact_missing_predicates_materialized=true" \
  "bounded_probe_truth_alignment_input_prepared=true"; do
  require_file_fact "$TRUTH_GAP_OWNER_LOG" "$fact"
done
for fact in \
  "truth_gap_matrix_consumed=true" \
  "fresh_bounded_runtime_native_probe_envelope_required=true" \
  "harness_gap_vs_host_limit_classification_required=true" \
  "renderer_state_write_readiness_closure_input_prepared=true"; do
  require_file_fact "$ALIGNMENT_OWNER_LOG" "$fact"
done
for fact in \
  "bounded_probe_truth_alignment_consumed=true" \
  "production_truth_gap_matrix_bound_to_write_readiness=true" \
  "renderer_state_write_readiness_closed_without_mutation=true" \
  "renderer_state_write_admission_ready=false"; do
  require_file_fact "$READINESS_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage129-suite-gap-$$" \
  zsh "$TRUTH_GAP_PACKET_SCRIPT" > "$TRUTH_GAP_PACKET_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: truth gap packet failed" >&2
  echo "cjgui stage129 write readiness suite: log=$TRUTH_GAP_PACKET_LOG" >&2
  exit 9
fi
truth_gap_packet="$(grep -Eo 'truth_gap_matrix_packet_path=[^[:space:]]+' "$TRUTH_GAP_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$truth_gap_packet" || ! -f "$truth_gap_packet" ]]; then
  echo "cjgui stage129 write readiness suite: missing truth gap matrix packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage129-suite-align-$$" \
  CJGUI_STAGE129_TRUTH_GAP_MATRIX_PACKET="$truth_gap_packet" \
  zsh "$ALIGNMENT_PACKET_SCRIPT" > "$ALIGNMENT_PACKET_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: alignment packet failed" >&2
  echo "cjgui stage129 write readiness suite: log=$ALIGNMENT_PACKET_LOG" >&2
  exit 11
fi
alignment_packet="$(grep -Eo 'bounded_probe_truth_alignment_packet_path=[^[:space:]]+' "$ALIGNMENT_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$alignment_packet" || ! -f "$alignment_packet" ]]; then
  echo "cjgui stage129 write readiness suite: missing bounded probe truth alignment packet" >&2
  exit 12
fi

if [[ "$(fact_value "$alignment_packet" "cjgui_harness_gap_detected")" == "true" ]]; then
  echo "cjgui stage129 write readiness suite: CJGUI harness gap detected by bounded probe" >&2
  echo "cjgui stage129 write readiness suite: packet=$alignment_packet" >&2
  exit 13
fi

if ! env CJGUI_STAGE129_TMPDIR="/tmp/cjgui-stage129-suite-ready-$$" \
  CJGUI_STAGE129_BOUNDED_PROBE_TRUTH_ALIGNMENT_PACKET="$alignment_packet" \
  zsh "$READINESS_PACKET_SCRIPT" > "$READINESS_PACKET_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: readiness packet failed" >&2
  echo "cjgui stage129 write readiness suite: log=$READINESS_PACKET_LOG" >&2
  exit 14
fi
readiness_packet="$(grep -Eo 'write_readiness_closure_packet_path=[^[:space:]]+' "$READINESS_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$readiness_packet" || ! -f "$readiness_packet" ]]; then
  echo "cjgui stage129 write readiness suite: missing write readiness closure packet" >&2
  exit 15
fi

for fact in \
  "stage129_terminal_write_denial_truth_gap_matrix_first_slice_packet_passed=true" \
  "production_truth_gap_matrix_ready=true" \
  "exact_missing_predicates_materialized=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$truth_gap_packet" "$fact"
done
for fact in \
  "stage129_terminal_write_denial_bounded_probe_truth_alignment_first_slice_packet_passed=true" \
  "bounded_probe_truth_alignment_packet_materialized=true" \
  "fresh_bounded_runtime_native_probe_executed=true" \
  "runtime_native_probe_execution=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$alignment_packet" "$fact"
done
for fact in \
  "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_packet_passed=true" \
  "renderer_state_write_readiness_closure_ready=true" \
  "renderer_state_write_admission_ready=false" \
  "production_truth_gap_closed=false" \
  "frame_hash_persistence_evidence_next_route_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$readiness_packet" "$fact"
done

for owner_file in \
  "$TRUTH_GAP_OWNER_FILE" \
  "$ALIGNMENT_OWNER_FILE" \
  "$READINESS_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage129 write readiness suite: public or foreign declaration found in $owner_file" >&2
    exit 16
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage129 write readiness suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 17
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage129 write readiness suite: protected path modified" >&2
  exit 18
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage129 write readiness suite: cjpm unavailable" >&2
  exit 19
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage129 write readiness suite: runtime package build failed" >&2
  echo "cjgui stage129 write readiness suite: log=$BUILD_LOG" >&2
  exit 20
fi

alignment_route="$(fact_value "$alignment_packet" "bounded_probe_truth_alignment_route_classification")"
probe_positive="$(fact_value "$alignment_packet" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$alignment_packet" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$alignment_packet" "cjgui_harness_gap_detected")"
first_frame_observed="$(fact_value "$alignment_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$alignment_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$alignment_packet" "frame_hash_nonzero")"
failure_domain="$(fact_value "$alignment_packet" "first_frame_observation_first_slice_failure_domain")"
runtime_native_probe_execution="$(fact_value "$readiness_packet" "runtime_native_probe_execution")"
write_blocked_by_probe="$(fact_value "$readiness_packet" "renderer_state_write_blocked_by_probe_classification")"

{
  echo "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_suite_version=1"
  echo "truth_gap_owner_log=$TRUTH_GAP_OWNER_LOG"
  echo "alignment_owner_log=$ALIGNMENT_OWNER_LOG"
  echo "readiness_owner_log=$READINESS_OWNER_LOG"
  echo "truth_gap_packet_log=$TRUTH_GAP_PACKET_LOG"
  echo "alignment_packet_log=$ALIGNMENT_PACKET_LOG"
  echo "readiness_packet_log=$READINESS_PACKET_LOG"
  echo "truth_gap_packet=$truth_gap_packet"
  echo "bounded_probe_truth_alignment_packet=$alignment_packet"
  echo "write_readiness_closure_packet=$readiness_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage129_truth_gap_matrix_owner_probe_passed=true"
  echo "stage129_bounded_probe_truth_alignment_owner_probe_passed=true"
  echo "stage129_renderer_state_write_readiness_closure_owner_probe_passed=true"
  echo "stage129_truth_gap_matrix_packet_passed=true"
  echo "stage129_bounded_probe_truth_alignment_packet_passed=true"
  echo "stage129_renderer_state_write_readiness_closure_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage129_public_foreign_scan_passed=true"
  echo "stage129_forbidden_native_render_token_scan_passed=true"
  echo "stage129_protected_path_scan_passed=true"
  echo "production_truth_gap_matrix_ready=true"
  echo "exact_missing_predicates_materialized=true"
  echo "bounded_probe_truth_alignment_route_classification=$alignment_route"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "first_frame_observation_first_slice_failure_domain=$failure_domain"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "renderer_state_write_readiness_closure_ready=true"
  echo "production_truth_gap_closed=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write_blocked_by_probe_classification=$write_blocked_by_probe"
  echo "frame_hash_persistence_evidence_next_route_prepared=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage129 write readiness suite: route_classification=stage129_terminal_write_denial_renderer_state_write_readiness_closure_first_slice_suite"
echo "cjgui stage129 write readiness suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage129 write readiness suite: bounded_probe_truth_alignment_route_classification=$alignment_route"
echo "cjgui stage129 write readiness suite: renderer_state_write_admission_ready=false"
echo "cjgui stage129 write readiness suite: renderer_state_write=false"
