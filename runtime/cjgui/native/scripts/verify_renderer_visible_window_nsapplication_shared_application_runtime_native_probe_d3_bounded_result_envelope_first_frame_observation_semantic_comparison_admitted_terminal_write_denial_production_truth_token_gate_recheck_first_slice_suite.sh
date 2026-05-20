#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage133 positive-probe materialization / production
# truth token gate / renderer-state write token gate 连续阶段包 focused suite。
# 它验证 fresh bounded probe 被重新物化，且 token/persistence/backend-ready
# predicate 缺失时不发生 production truth 或 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE133_TMPDIR:-/tmp/cjgui-stage133-production-truth-token-gate-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

SCRIPT_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"
SRC_PREFIX="runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"

MATERIALIZATION_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_positive_probe_materialization_first_slice_owner.sh"
TRUTH_GATE_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_production_truth_token_gate_recheck_first_slice_owner.sh"
STATE_GATE_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_renderer_state_write_token_gate_recheck_first_slice_owner.sh"
MATERIALIZATION_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_positive_probe_materialization_first_slice_packet.sh"
TRUTH_GATE_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_production_truth_token_gate_recheck_first_slice_packet.sh"
STATE_GATE_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_renderer_state_write_token_gate_recheck_first_slice_packet.sh"

MATERIALIZATION_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_positive_probe_materialization_first_slice.cj"
TRUTH_GATE_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_production_truth_token_gate_recheck_first_slice.cj"
STATE_GATE_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_renderer_state_write_token_gate_recheck_first_slice.cj"

MATERIALIZATION_OWNER_LOG="$TMP_DIR/materialization-owner.log"
TRUTH_GATE_OWNER_LOG="$TMP_DIR/truth-gate-owner.log"
STATE_GATE_OWNER_LOG="$TMP_DIR/state-gate-owner.log"
MATERIALIZATION_PACKET_LOG="$TMP_DIR/materialization-packet.log"
TRUTH_GATE_PACKET_LOG="$TMP_DIR/truth-gate-packet.log"
STATE_GATE_PACKET_LOG="$TMP_DIR/state-gate-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage133-production-truth-token-gate-recheck-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$MATERIALIZATION_OWNER_LOG"
: > "$TRUTH_GATE_OWNER_LOG"
: > "$STATE_GATE_OWNER_LOG"
: > "$MATERIALIZATION_PACKET_LOG"
: > "$TRUTH_GATE_PACKET_LOG"
: > "$STATE_GATE_PACKET_LOG"
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
    echo "cjgui stage133 token gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in \
  "$MATERIALIZATION_OWNER" \
  "$TRUTH_GATE_OWNER" \
  "$STATE_GATE_OWNER" \
  "$MATERIALIZATION_PACKET_SCRIPT" \
  "$TRUTH_GATE_PACKET_SCRIPT" \
  "$STATE_GATE_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage133 token gate suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage133 token gate suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$MATERIALIZATION_OWNER" > "$MATERIALIZATION_OWNER_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: materialization owner failed" >&2
  echo "cjgui stage133 token gate suite: log=$MATERIALIZATION_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$TRUTH_GATE_OWNER" > "$TRUTH_GATE_OWNER_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: truth gate owner failed" >&2
  echo "cjgui stage133 token gate suite: log=$TRUTH_GATE_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$STATE_GATE_OWNER" > "$STATE_GATE_OWNER_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: state gate owner failed" >&2
  echo "cjgui stage133 token gate suite: log=$STATE_GATE_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "positive_probe_materialization_ready=true" \
  "fresh_bounded_first_frame_probe_materialization_required=true" \
  "production_truth_token_gate_recheck_input_prepared=true"; do
  require_file_fact "$MATERIALIZATION_OWNER_LOG" "$fact"
done
for fact in \
  "production_truth_token_gate_recheck_ready=true" \
  "production_truth_requires_backing_store_token=true" \
  "renderer_state_write_token_gate_recheck_input_prepared=true"; do
  require_file_fact "$TRUTH_GATE_OWNER_LOG" "$fact"
done
for fact in \
  "renderer_state_write_token_gate_recheck_ready=true" \
  "renderer_state_write_requires_production_truth=true" \
  "positive_host_rerun_next_route_prepared=true"; do
  require_file_fact "$STATE_GATE_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage133-suite-materialization-$$" \
  zsh "$MATERIALIZATION_PACKET_SCRIPT" > "$MATERIALIZATION_PACKET_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: materialization packet failed" >&2
  echo "cjgui stage133 token gate suite: log=$MATERIALIZATION_PACKET_LOG" >&2
  exit 9
fi
materialization_packet="$(grep -Eo 'positive_probe_materialization_packet_path=[^[:space:]]+' "$MATERIALIZATION_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$materialization_packet" || ! -f "$materialization_packet" ]]; then
  echo "cjgui stage133 token gate suite: missing materialization packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage133-suite-truth-gate-$$" \
  CJGUI_STAGE133_POSITIVE_PROBE_MATERIALIZATION_PACKET="$materialization_packet" \
  zsh "$TRUTH_GATE_PACKET_SCRIPT" > "$TRUTH_GATE_PACKET_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: truth gate packet failed" >&2
  echo "cjgui stage133 token gate suite: log=$TRUTH_GATE_PACKET_LOG" >&2
  exit 11
fi
truth_gate_packet="$(grep -Eo 'production_truth_token_gate_recheck_packet_path=[^[:space:]]+' "$TRUTH_GATE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$truth_gate_packet" || ! -f "$truth_gate_packet" ]]; then
  echo "cjgui stage133 token gate suite: missing truth gate packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage133-suite-state-gate-$$" \
  CJGUI_STAGE133_PRODUCTION_TRUTH_TOKEN_GATE_PACKET="$truth_gate_packet" \
  zsh "$STATE_GATE_PACKET_SCRIPT" > "$STATE_GATE_PACKET_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: state gate packet failed" >&2
  echo "cjgui stage133 token gate suite: log=$STATE_GATE_PACKET_LOG" >&2
  exit 13
fi
state_gate_packet="$(grep -Eo 'renderer_state_write_token_gate_recheck_packet_path=[^[:space:]]+' "$STATE_GATE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$state_gate_packet" || ! -f "$state_gate_packet" ]]; then
  echo "cjgui stage133 token gate suite: missing state gate packet" >&2
  exit 14
fi

for fact in \
  "stage133_positive_probe_materialization_first_slice_packet_passed=true" \
  "fresh_bounded_first_frame_probe_executed=true" \
  "positive_probe_facts_kept_isolated=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$materialization_packet" "$fact"
done
for fact in \
  "stage133_production_truth_token_gate_recheck_first_slice_packet_passed=true" \
  "production_truth_token_gate_recheck_ready=true" \
  "production_truth_requires_backing_store_token=true" \
  "production_truth_requires_frame_hash_persistence_commit=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$truth_gate_packet" "$fact"
done
for fact in \
  "stage133_renderer_state_write_token_gate_recheck_first_slice_packet_passed=true" \
  "renderer_state_write_token_gate_recheck_ready=true" \
  "renderer_state_write_requires_production_truth=true" \
  "renderer_state_write_requires_backend_ready_truth=true" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$state_gate_packet" "$fact"
done

for owner_file in \
  "$MATERIALIZATION_OWNER_FILE" \
  "$TRUTH_GATE_OWNER_FILE" \
  "$STATE_GATE_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage133 token gate suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|presentDrawable|commit\]|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' >/dev/null 2>&1; then
    echo "cjgui stage133 token gate suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage133 token gate suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage133 token gate suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage133 token gate suite: runtime package build failed" >&2
  echo "cjgui stage133 token gate suite: log=$BUILD_LOG" >&2
  exit 19
fi

positive_live_probe="$(fact_value "$materialization_packet" "positive_live_probe_observed")"
nonzero_hash="$(fact_value "$materialization_packet" "nonzero_frame_hash_observed")"
host_limit="$(fact_value "$materialization_packet" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$materialization_packet" "cjgui_harness_gap_detected")"
route_classification="$(fact_value "$materialization_packet" "positive_probe_materialization_route_classification")"
truth_block_reason="$(fact_value "$truth_gate_packet" "production_truth_token_gate_block_reason")"
state_block_reason="$(fact_value "$state_gate_packet" "renderer_state_write_block_reason")"
backing_store_token_issued="$(fact_value "$truth_gate_packet" "backing_store_token_issued")"
frame_hash_persistence_commit_admitted="$(fact_value "$truth_gate_packet" "frame_hash_persistence_commit_admitted")"
result_envelope_promoted_to_production_truth="$(fact_value "$truth_gate_packet" "result_envelope_promoted_to_production_truth")"
production_render_truth="$(fact_value "$truth_gate_packet" "production_render_truth")"

{
  echo "stage133_production_truth_token_gate_recheck_first_slice_suite_version=1"
  echo "materialization_owner_log=$MATERIALIZATION_OWNER_LOG"
  echo "truth_gate_owner_log=$TRUTH_GATE_OWNER_LOG"
  echo "state_gate_owner_log=$STATE_GATE_OWNER_LOG"
  echo "materialization_packet_log=$MATERIALIZATION_PACKET_LOG"
  echo "truth_gate_packet_log=$TRUTH_GATE_PACKET_LOG"
  echo "state_gate_packet_log=$STATE_GATE_PACKET_LOG"
  echo "positive_probe_materialization_packet=$materialization_packet"
  echo "production_truth_token_gate_recheck_packet=$truth_gate_packet"
  echo "renderer_state_write_token_gate_recheck_packet=$state_gate_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage133_positive_probe_materialization_owner_probe_passed=true"
  echo "stage133_production_truth_token_gate_recheck_owner_probe_passed=true"
  echo "stage133_renderer_state_write_token_gate_recheck_owner_probe_passed=true"
  echo "stage133_positive_probe_materialization_packet_passed=true"
  echo "stage133_production_truth_token_gate_recheck_packet_passed=true"
  echo "stage133_renderer_state_write_token_gate_recheck_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage133_public_foreign_scan_passed=true"
  echo "stage133_forbidden_native_render_token_scan_passed=true"
  echo "stage133_protected_path_scan_passed=true"
  echo "fresh_bounded_first_frame_probe_executed=true"
  echo "positive_probe_materialization_route_classification=$route_classification"
  echo "positive_live_probe_observed=$positive_live_probe"
  echo "nonzero_frame_hash_observed=$nonzero_hash"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "backing_store_token_issued=$backing_store_token_issued"
  echo "frame_hash_persistence_commit_admitted=$frame_hash_persistence_commit_admitted"
  echo "production_truth_token_gate_recheck_ready=true"
  echo "production_truth_token_gate_block_reason=$truth_block_reason"
  echo "result_envelope_promoted_to_production_truth=$result_envelope_promoted_to_production_truth"
  echo "production_render_truth=$production_render_truth"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_token_gate_recheck_ready=true"
  echo "renderer_state_write_block_reason=$state_block_reason"
  echo "renderer_state_write_admission_ready=false"
  echo "runtime_native_probe_execution=true"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "next_route=rerun_bounded_first_frame_probe_on_metal_capable_host_or_promote_after_tokenized_persistence"
  echo "stage133_production_truth_token_gate_recheck_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage133 token gate suite: route_classification=stage133_production_truth_token_gate_recheck_first_slice_suite"
echo "cjgui stage133 token gate suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage133 token gate suite: result_envelope_promoted_to_production_truth=$result_envelope_promoted_to_production_truth"
echo "cjgui stage133 token gate suite: renderer_state_write=false"
