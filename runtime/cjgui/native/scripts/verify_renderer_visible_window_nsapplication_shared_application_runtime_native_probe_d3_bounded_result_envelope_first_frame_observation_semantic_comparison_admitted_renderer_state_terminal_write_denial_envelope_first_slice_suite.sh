#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage128 visibility publication denial /
# rollback fallback denial envelope / terminal write denial envelope 连续阶段包
# focused suite。它串联三个 owner probe、三个 packet 与 build/scan，
# 不执行真实 renderer state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE128_TMPDIR:-/tmp/cjgui-stage128-terminal-write-denial-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

VISIBILITY_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_owner.sh"
ROLLBACK_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_owner.sh"
TERMINAL_OWNER="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_owner.sh"
VISIBILITY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet.sh"
ROLLBACK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet.sh"
TERMINAL_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet.sh"

VISIBILITY_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice.cj"
ROLLBACK_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice.cj"
TERMINAL_OWNER_FILE="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice.cj"

VISIBILITY_OWNER_LOG="$TMP_DIR/visibility-owner.log"
ROLLBACK_OWNER_LOG="$TMP_DIR/rollback-owner.log"
TERMINAL_OWNER_LOG="$TMP_DIR/terminal-owner.log"
VISIBILITY_PACKET_LOG="$TMP_DIR/visibility-packet.log"
ROLLBACK_PACKET_LOG="$TMP_DIR/rollback-packet.log"
TERMINAL_PACKET_LOG="$TMP_DIR/terminal-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-terminal-write-denial-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$VISIBILITY_OWNER_LOG"
: > "$ROLLBACK_OWNER_LOG"
: > "$TERMINAL_OWNER_LOG"
: > "$VISIBILITY_PACKET_LOG"
: > "$ROLLBACK_PACKET_LOG"
: > "$TERMINAL_PACKET_LOG"
: > "$BUILD_LOG"
: > "$SUITE_PACKET"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

for script in \
  "$VISIBILITY_OWNER" \
  "$ROLLBACK_OWNER" \
  "$TERMINAL_OWNER" \
  "$VISIBILITY_PACKET_SCRIPT" \
  "$ROLLBACK_PACKET_SCRIPT" \
  "$TERMINAL_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage128 terminal write denial suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage128 terminal write denial suite: syntax check failed $script" >&2
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
    echo "cjgui stage128 terminal write denial suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if ! zsh "$VISIBILITY_OWNER" > "$VISIBILITY_OWNER_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: visibility owner failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$VISIBILITY_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$ROLLBACK_OWNER" > "$ROLLBACK_OWNER_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: rollback owner failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$ROLLBACK_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$TERMINAL_OWNER" > "$TERMINAL_OWNER_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: terminal owner failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$TERMINAL_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true" \
  "guarded_executor_result_envelope_consumed=true" \
  "visibility_publication_denial_envelope_materialized=true" \
  "visibility_publication_denied=true"; do
  require_file_fact "$VISIBILITY_OWNER_LOG" "$fact"
done
for fact in \
  "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true" \
  "visibility_publication_denial_consumed=true" \
  "rollback_fallback_denial_envelope_materialized=true" \
  "rollback_fallback_state_write_denied=true"; do
  require_file_fact "$ROLLBACK_OWNER_LOG" "$fact"
done
for fact in \
  "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true" \
  "rollback_fallback_denial_envelope_consumed=true" \
  "terminal_write_denial_envelope_materialized=true" \
  "terminal_renderer_state_write_denied=true"; do
  require_file_fact "$TERMINAL_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE128_TMPDIR="/tmp/cjgui-stage128-suite-visibility-$$" \
  zsh "$VISIBILITY_PACKET_SCRIPT" > "$VISIBILITY_PACKET_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: visibility packet failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$VISIBILITY_PACKET_LOG" >&2
  exit 9
fi
visibility_packet="$(grep -Eo 'visibility_publication_denial_packet_path=[^[:space:]]+' "$VISIBILITY_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$visibility_packet" || ! -f "$visibility_packet" ]]; then
  echo "cjgui stage128 terminal write denial suite: missing visibility packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE128_TMPDIR="/tmp/cjgui-stage128-suite-rollback-$$" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_VISIBILITY_PUBLICATION_DENIAL_FIRST_SLICE_PACKET="$visibility_packet" \
  zsh "$ROLLBACK_PACKET_SCRIPT" > "$ROLLBACK_PACKET_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: rollback packet failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$ROLLBACK_PACKET_LOG" >&2
  exit 11
fi
rollback_packet="$(grep -Eo 'rollback_fallback_denial_envelope_packet_path=[^[:space:]]+' "$ROLLBACK_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$rollback_packet" || ! -f "$rollback_packet" ]]; then
  echo "cjgui stage128 terminal write denial suite: missing rollback packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE128_TMPDIR="/tmp/cjgui-stage128-suite-terminal-$$" \
  CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_ROLLBACK_FALLBACK_DENIAL_ENVELOPE_FIRST_SLICE_PACKET="$rollback_packet" \
  zsh "$TERMINAL_PACKET_SCRIPT" > "$TERMINAL_PACKET_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: terminal packet failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$TERMINAL_PACKET_LOG" >&2
  exit 13
fi
terminal_packet="$(grep -Eo 'terminal_write_denial_envelope_packet_path=[^[:space:]]+' "$TERMINAL_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$terminal_packet" || ! -f "$terminal_packet" ]]; then
  echo "cjgui stage128 terminal write denial suite: missing terminal packet" >&2
  exit 14
fi

for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true" \
  "visibility_publication_denied=true" \
  "rollback_fallback_denial_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$visibility_packet" "$fact"
done
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true" \
  "visibility_denial_bound_to_rollback_fallback_stop_line=true" \
  "rollback_fallback_state_write_denied=true" \
  "terminal_write_denial_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$rollback_packet" "$fact"
done
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=true" \
  "terminal_write_denial_envelope_materialized=true" \
  "visibility_publication_denial_persisted_as_terminal_dry_run_fact=true" \
  "rollback_fallback_denial_persisted_as_terminal_dry_run_fact=true" \
  "terminal_renderer_state_write_denied=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$terminal_packet" "$fact"
done

for owner_file in \
  "$VISIBILITY_OWNER_FILE" \
  "$ROLLBACK_OWNER_FILE" \
  "$TERMINAL_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage128 terminal write denial suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage128 terminal write denial suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage128 terminal write denial suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage128 terminal write denial suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage128 terminal write denial suite: runtime package build failed" >&2
  echo "cjgui stage128 terminal write denial suite: log=$BUILD_LOG" >&2
  exit 19
fi

runtime_native_probe_execution="$(fact_value "$terminal_packet" "runtime_native_probe_execution")"
visibility_ready="$(fact_value "$visibility_packet" "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready")"
rollback_ready="$(fact_value "$rollback_packet" "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready")"
terminal_ready="$(fact_value "$terminal_packet" "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready")"

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite_version=1"
  echo "visibility_owner_log=$VISIBILITY_OWNER_LOG"
  echo "rollback_owner_log=$ROLLBACK_OWNER_LOG"
  echo "terminal_owner_log=$TERMINAL_OWNER_LOG"
  echo "visibility_packet_log=$VISIBILITY_PACKET_LOG"
  echo "rollback_packet_log=$ROLLBACK_PACKET_LOG"
  echo "terminal_packet_log=$TERMINAL_PACKET_LOG"
  echo "visibility_packet=$visibility_packet"
  echo "rollback_packet=$rollback_packet"
  echo "terminal_packet=$terminal_packet"
  echo "build_log=$BUILD_LOG"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet_passed=true"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_first_slice_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage128_public_foreign_scan_passed=true"
  echo "stage128_forbidden_native_render_token_scan_passed=true"
  echo "stage128_protected_path_scan_passed=true"
  echo "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=$visibility_ready"
  echo "visibility_publication_denial_envelope_materialized=true"
  echo "visibility_publication_denied=true"
  echo "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=$rollback_ready"
  echo "rollback_fallback_denial_envelope_materialized=true"
  echo "rollback_fallback_state_write_denied=true"
  echo "semantic_comparison_admitted_renderer_state_terminal_write_denial_envelope_ready=$terminal_ready"
  echo "terminal_write_denial_envelope_materialized=true"
  echo "terminal_renderer_state_write_denied=true"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage128 terminal write denial suite: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite"
echo "cjgui stage128 terminal write denial suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage128 terminal write denial suite: d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_envelope_first_slice_suite_passed=true"
echo "cjgui stage128 terminal write denial suite: renderer_state_write=false"
