#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage127 renderer-state mutation request result /
# guarded state-write executor dry-run / guarded executor result envelope
# 连续阶段包 focused suite。它串联三个 owner probe、三个 packet 与
# source/build/protected scan，不执行真实 renderer state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE127_TMPDIR:-/tmp/cjgui-stage127-guarded-result-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

MUTATION_REQUEST_RESULT_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_owner.sh"
GUARDED_EXECUTOR_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_dry_run_first_slice_owner.sh"
GUARDED_RESULT_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice_owner.sh"
MUTATION_REQUEST_RESULT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet.sh"
GUARDED_EXECUTOR_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_dry_run_first_slice_packet.sh"
GUARDED_RESULT_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice_packet.sh"

MUTATION_REQUEST_RESULT_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice.cj"
GUARDED_EXECUTOR_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_dry_run_first_slice.cj"
GUARDED_RESULT_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_guarded_state_write_executor_result_envelope_first_slice.cj"

MUTATION_REQUEST_RESULT_OWNER_LOG="$TMP_DIR/mutation-request-result-owner.log"
GUARDED_EXECUTOR_OWNER_LOG="$TMP_DIR/guarded-executor-owner.log"
GUARDED_RESULT_OWNER_LOG="$TMP_DIR/guarded-result-owner.log"
MUTATION_REQUEST_RESULT_PACKET_LOG="$TMP_DIR/mutation-request-result-packet.log"
GUARDED_EXECUTOR_PACKET_LOG="$TMP_DIR/guarded-executor-packet.log"
GUARDED_RESULT_PACKET_LOG="$TMP_DIR/guarded-result-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-guarded-state-write-executor-result-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$MUTATION_REQUEST_RESULT_OWNER_LOG"
: > "$GUARDED_EXECUTOR_OWNER_LOG"
: > "$GUARDED_RESULT_OWNER_LOG"
: > "$MUTATION_REQUEST_RESULT_PACKET_LOG"
: > "$GUARDED_EXECUTOR_PACKET_LOG"
: > "$GUARDED_RESULT_PACKET_LOG"
: > "$BUILD_LOG"
: > "$SUITE_PACKET"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in \
  "$MUTATION_REQUEST_RESULT_OWNER" \
  "$GUARDED_EXECUTOR_OWNER" \
  "$GUARDED_RESULT_OWNER" \
  "$MUTATION_REQUEST_RESULT_PACKET_SCRIPT" \
  "$GUARDED_EXECUTOR_PACKET_SCRIPT" \
  "$GUARDED_RESULT_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage127 guarded executor suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage127 guarded executor suite: syntax check failed $script" >&2
    exit 4
  fi
done

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
    echo "cjgui stage127 guarded executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$MUTATION_REQUEST_RESULT_OWNER" > "$MUTATION_REQUEST_RESULT_OWNER_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: mutation request result owner failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$MUTATION_REQUEST_RESULT_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$GUARDED_EXECUTOR_OWNER" > "$GUARDED_EXECUTOR_OWNER_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: guarded executor owner failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$GUARDED_EXECUTOR_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$GUARDED_RESULT_OWNER" > "$GUARDED_RESULT_OWNER_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: guarded result owner failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$GUARDED_RESULT_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true" \
  "renderer_state_mutation_request_result_envelope_materialized=true" \
  "rollback_eligibility_blocked=true" \
  "guarded_state_write_executor_input_prepared=true"; do
  require_file_fact "$MUTATION_REQUEST_RESULT_OWNER_LOG" "$fact"
done
for fact in \
  "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true" \
  "guarded_state_write_executor_inputs_defined=true" \
  "mutation_request_rejection_bound_to_executor_denial=true" \
  "guarded_state_write_executor_denied=true"; do
  require_file_fact "$GUARDED_EXECUTOR_OWNER_LOG" "$fact"
done
for fact in \
  "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true" \
  "guarded_state_write_executor_result_envelope_materialized=true" \
  "guarded_executor_denial_persisted_as_dry_run_fact=true" \
  "visibility_publication_denial_input_prepared=true"; do
  require_file_fact "$GUARDED_RESULT_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-suite-mr-result-$$" \
  zsh "$MUTATION_REQUEST_RESULT_PACKET_SCRIPT" > "$MUTATION_REQUEST_RESULT_PACKET_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: mutation request result packet failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$MUTATION_REQUEST_RESULT_PACKET_LOG" >&2
  exit 9
fi
mutation_request_result_packet="$(grep -Eo 'mutation_request_result_envelope_packet_path=[^[:space:]]+' "$MUTATION_REQUEST_RESULT_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$mutation_request_result_packet" || ! -f "$mutation_request_result_packet" ]]; then
  echo "cjgui stage127 guarded executor suite: missing mutation request result packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-suite-guarded-exec-$$" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_RESULT_ENVELOPE_FIRST_SLICE_PACKET="$mutation_request_result_packet" \
  zsh "$GUARDED_EXECUTOR_PACKET_SCRIPT" > "$GUARDED_EXECUTOR_PACKET_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: guarded executor packet failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$GUARDED_EXECUTOR_PACKET_LOG" >&2
  exit 11
fi
guarded_executor_packet="$(grep -Eo 'guarded_state_write_executor_packet_path=[^[:space:]]+' "$GUARDED_EXECUTOR_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$guarded_executor_packet" || ! -f "$guarded_executor_packet" ]]; then
  echo "cjgui stage127 guarded executor suite: missing guarded executor packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE127_TMPDIR="/tmp/cjgui-stage127-suite-guarded-result-$$" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_GUARDED_STATE_WRITE_EXECUTOR_DRY_RUN_FIRST_SLICE_PACKET="$guarded_executor_packet" \
  zsh "$GUARDED_RESULT_PACKET_SCRIPT" > "$GUARDED_RESULT_PACKET_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: guarded result packet failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$GUARDED_RESULT_PACKET_LOG" >&2
  exit 13
fi
guarded_result_packet="$(grep -Eo 'guarded_executor_result_envelope_packet_path=[^[:space:]]+' "$GUARDED_RESULT_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$guarded_result_packet" || ! -f "$guarded_result_packet" ]]; then
  echo "cjgui stage127 guarded executor suite: missing guarded result packet" >&2
  exit 14
fi

for fact in \
  "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true" \
  "renderer_state_mutation_request_result_envelope_materialized=true" \
  "mutation_request_rejection_persisted_as_dry_run_fact=true" \
  "rollback_eligibility_blocked=true" \
  "guarded_state_write_executor_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$mutation_request_result_packet" "$fact"
done
for fact in \
  "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=true" \
  "guarded_state_write_executor_inputs_defined=true" \
  "mutation_request_rejection_bound_to_executor_denial=true" \
  "rollback_eligibility_bound_to_executor_stop_line=true" \
  "guarded_state_write_executor_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$guarded_executor_packet" "$fact"
done
for fact in \
  "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=true" \
  "guarded_state_write_executor_result_envelope_materialized=true" \
  "guarded_executor_denial_persisted_as_dry_run_fact=true" \
  "rollback_stop_line_persisted_as_dry_run_fact=true" \
  "visibility_publication_denial_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$guarded_result_packet" "$fact"
done

for owner_file in \
  "$MUTATION_REQUEST_RESULT_OWNER_FILE" \
  "$GUARDED_EXECUTOR_OWNER_FILE" \
  "$GUARDED_RESULT_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage127 guarded executor suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage127 guarded executor suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage127 guarded executor suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage127 guarded executor suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage127 guarded executor suite: runtime package build failed" >&2
  echo "cjgui stage127 guarded executor suite: log=$BUILD_LOG" >&2
  exit 19
fi

runtime_native_probe_execution="$(fact_value "$guarded_result_packet" "runtime_native_probe_execution")"
guarded_executor_ready="$(fact_value "$guarded_executor_packet" "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready")"
guarded_result_ready="$(fact_value "$guarded_result_packet" "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite_version=1"
  echo "mutation_request_result_owner_log=$MUTATION_REQUEST_RESULT_OWNER_LOG"
  echo "guarded_executor_owner_log=$GUARDED_EXECUTOR_OWNER_LOG"
  echo "guarded_result_owner_log=$GUARDED_RESULT_OWNER_LOG"
  echo "mutation_request_result_packet_log=$MUTATION_REQUEST_RESULT_PACKET_LOG"
  echo "guarded_executor_packet_log=$GUARDED_EXECUTOR_PACKET_LOG"
  echo "guarded_result_packet_log=$GUARDED_RESULT_PACKET_LOG"
  echo "mutation_request_result_packet=$mutation_request_result_packet"
  echo "guarded_executor_packet=$guarded_executor_packet"
  echo "guarded_result_packet=$guarded_result_packet"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_dry_run_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage127_public_foreign_scan_passed=true"
  echo "stage127_forbidden_native_render_token_scan_passed=true"
  echo "stage127_protected_path_scan_passed=true"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_result_envelope_ready=true"
  echo "renderer_state_mutation_request_result_envelope_materialized=true"
  echo "mutation_request_rejection_persisted_as_dry_run_fact=true"
  echo "rollback_eligibility_blocked=true"
  echo "guarded_state_write_executor_input_prepared=true"
  echo "semantic_comparison_admitted_guarded_state_write_executor_dry_run_ready=$guarded_executor_ready"
  echo "guarded_state_write_executor_inputs_defined=true"
  echo "mutation_request_rejection_bound_to_executor_denial=true"
  echo "rollback_eligibility_bound_to_executor_stop_line=true"
  echo "guarded_state_write_executor_non_executable=true"
  echo "guarded_state_write_executor_dry_run_only=true"
  echo "guarded_state_write_executor_denied=true"
  echo "semantic_comparison_admitted_guarded_state_write_executor_result_envelope_ready=$guarded_result_ready"
  echo "guarded_state_write_executor_result_envelope_materialized=true"
  echo "guarded_executor_denial_persisted_as_dry_run_fact=true"
  echo "rollback_stop_line_persisted_as_dry_run_fact=true"
  echo "visibility_publication_denial_input_prepared=true"
  echo "visibility_publication_blocked=true"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage127 guarded executor suite: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite"
echo "cjgui stage127 guarded executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage127 guarded executor suite: d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_guarded_state_write_executor_result_envelope_first_slice_suite_passed=true"
echo "cjgui stage127 guarded executor suite: renderer_state_write=false"
